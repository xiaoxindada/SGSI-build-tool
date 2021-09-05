#!/bin/bash

# Project OEM-GSI Porter by Erfan Abdi <erfangplus@gmail.com>

PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

AB=true
AONLY=false
MOUNTED=false
NOVNDK=false
CLEAN=true
DYNAMIC=false

usage()
{
    echo "Usage: [--help|-h|-?] [--ab|-b] [--aonly|-a] [--mounted|-m] [--cleanup|-c] [--dynamic|-d] [--no-vndks|-nv] $0 <Firmware link> <Firmware type> [Other args]"
    echo -e "\tFirmware link: Firmware download link or local path"
    echo -e "\tFirmware type: Firmware mode"
    echo -e "\t--ab: Build only AB"
    echo -e "\t--aonly: Build only A-Only"
    echo -e "\t--cleanup: Cleanup downloaded firmware"
    echo -e "\t--dynamic: Use this option only if the firmware contains dynamic partitions"
    echo -e "\t--novndk: Do not include extra VNDK"
    echo -e "\t--help: To show this info"
}

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    --ab|-b)
    AONLY=false
    AB=true
    shift
    ;;
    --aonly|-a)
    AONLY=true
    AB=false
    shift
    ;;
    --cleanup|-c)
    CLEAN=true
    shift
    ;;
    --no-vndks|-nv)
    NOVNDK=true
    shift
    ;;
    --dynamic|-d)
    DYNAMIC=true
    shift
    ;;
    --help|-h|-?)
    usage
    exit
    ;;
    *)
    POSITIONAL+=("$1")
    shift
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

if [[ ! -n $2 ]]; then
    echo "-> ERROR!"
    echo " - Enter all needed parameters"
    usage
    exit
fi

URL=$1
shift
SRCTYPE=$1
shift

ORIGINAL_URL=$URL

if [[ $SRCTYPE == *":"* ]]; then
    SRCTYPENAME=`echo "$SRCTYPE" | cut -d ":" -f 2`
else
    SRCTYPENAME=$SRCTYPE
fi

DOWNLOAD()
{
    URL="$1"
    ZIP_NAME="update.zip"
    echo "-> Downloading firmware..."
            mkdir ./tmp
            aria2c -x16 -j$(nproc) -U "Mozilla/5.0" -d "XiaoxindadaSGSIs/tmp" -o $ZIP_NAME $URL || wget -U "Mozilla/5.0" $URL -O "XiaoxindadaSGSIs/tmp/$ZIP_NAME"
            echo "zip_file: $(ls "XiaoxindadaSGSIs/tmp/")"
            ls

if [ $AB == true ]; then
   "$PROJECT_DIR"/make.sh AB "${SRCTYPE}" "XiaoxindadaSGSIs/tmp/update.zip" || LEAVE
fi

echo "-> Porting GSI done!"
