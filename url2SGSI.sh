#!/bin/bash

# Inspired from url2GSI from ErfanGSIs tool at https://github.com/erfanoabdi/ErfanGSIs
# Copyright to Rahul at https://github.com/rahulkhatri137

LOCALDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source ./bin.sh
source ./language_helper.sh
fixbug=true
build="--ab"

usage() {
cat <<EOT
Usage:
$0 <Firmware link> <Firmware type> <Build Type> <Fixbug>
   Firmware link: Firmware download link or local path
   Firmware type: Firmware source type
   Build Type: [--ab|-ab|--AB|-AB] or [--a|-a|-A|--A]
   Fixbug: [--fb|-fb] to disable Fixbug
EOT
}

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    --help|-h|-?)
    usage
    exit 1
    ;;
    --fb|-fb)
    fixbug=false
    shift
    ;;
    --ab|-ab|--AB|-AB)
    build="-ab"
    shift
    ;;
    --a|-a|-A|--A)
    build="-a"
    shift
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
    exit 1
fi

URL=$1
shift
TYPE=$1
shift

ORIGINAL_URL=$URL

if ! (cat $LOCALDIR/make/rom_support_list.txt | grep -qo "$TYPE");then
  echo $UNSUPPORTED_ROM
  echo $SUPPORTED_ROM_LIST
  cat $LOCALDIR/make/rom_support_list.txt
  exit 1
fi

rm -rf tmp output workspace SGSI

URL="$1"
if [[ "$URL" == "http"* ]]; then
echo "Downloading firmware..."
mkdir -p "$LOCALDIR/tmp"
ZIP="$LOCALDIR/tmp/update.zip"
ZIP_NAME="update.zip"
aria2c -x16 -j$(nproc) -U "Mozilla/5.0" -d "$LOCALDIR/tmp" -o "$ZIP_NAME" ${URL} > /dev/null 2>&1
URL="$ZIP"
fi

LEAVE() {
    echo "SGSI failed! Exiting..."
    rm -rf "$LOCALDIR/output" "$LOCALDIR/workspace" "$LOCALDIR/tmp" "$LOCALDIR/SGSI"
    exit 1
}
if [ $fixbug == true ]; then
    "$LOCALDIR"/make.sh $build $TYPE $URL --fix-bug || LEAVE
elif [ $fixbug == false ] ; then
    "$LOCALDIR"/make.sh $build $TYPE $URL || LEAVE
fi

rm -rf "$LOCALDIR/tmp"
rm -rf "$LOCALDIR/workspace"
if [ -d "$LOCALDIR/SGSI" ]; then
   echo "Porting SGSI done!"
else
   LEAVE
fi
