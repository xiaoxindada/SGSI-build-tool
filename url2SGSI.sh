#!/bin/bash

# Inspired from url2GSI from ErfanGSIs tool at https://github.com/erfanoabdi/ErfanGSIs
# Rebased: Rahul at https://github.com/rahulkhatri137
# Final change: Xiaoxindada at https://github.com/xiaoxindada

LOCALDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source ./bin.sh
fixbug=true
build="--ab"

usage() {
cat <<EOT
Usage:
$0 <Firmware link> <Firmware type> <Build Type> <Fixbug>
   Firmware link: Firmware download link or local path
   Firmware type: Firmware source type
   Build Type: ab or a
   Fixbug: [fb|--fb|-fb] to disable Fixbug
EOT
exit 1
}

if [ $# -lt 2 ];then
  usage
fi

case "$1" in
    --help|-h|-?)
    usage
    ;;
esac

URL=$1
shift

TYPE=$1
shift

if ! (cat $COMPONENT/rom_support_list.txt | grep -qo "$TYPE");then
  echo "Current rom type not support"
  echo "List of supported:"
  cat $COMPONENT/rom_support_list.txt
  exit 1
fi

build="$1"
case $build in
    ab|AB|--ab|-ab|--AB|-AB)
    build="--ab"
    shift
    ;;
    a|A|--a|-a|-A|--A)
    build="-a"
    shift
    ;;
    *)
    build="--ab"
    ;;
esac

fixbug="$1"
case $fixbug in
    fb|--fb|--FB|-fb|-FB)
    fixbug=false
    shift
    ;;
    *)
    fixbug=true
    shift
    ;;
esac

rm -rf tmp output workspace SGSI

LEAVE() {
    echo "SGSI failed! Exiting..."
    rm -rf "$LOCALDIR/output" "$LOCALDIR/workspace" "$LOCALDIR/tmp" "$LOCALDIR/SGSI"
    exit 1
}

if [[ "$URL" == "http"* ]]; then
  echo "Downloading firmware..."
  mkdir -p "$LOCALDIR/tmp"
  ZIP="$LOCALDIR/tmp/update.zip"
  ZIP_NAME="update.zip"
  aria2c -x16 -j$(nproc) -U "Mozilla/5.0" -d "$LOCALDIR/tmp" -o "$ZIP_NAME" ${URL}
else
  echo "Url not support!"
  exit 1
fi

if [ $fixbug == true ]; then
  "$LOCALDIR"/make.sh $build $TYPE $ZIP --fix-bug || LEAVE
elif [ $fixbug == false ] ; then
  "$LOCALDIR"/make.sh $build $TYPE $ZIP || LEAVE
fi

rm -rf "$LOCALDIR/tmp"
rm -rf "$LOCALDIR/workspace"
if [ -d "$LOCALDIR/SGSI" ]; then
   echo "Porting SGSI done!"
else
  LEAVE
fi
