#!/bin/bash

PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

DL="${PROJECT_DIR}/dl.sh"

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    *)
    POSITIONAL+=("$1")
    shift
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

URL=$1
shift
TYPE=$1
shift

ORIGINAL_URL=$URL
if [[ $TYPE == *":"* ]]; then
    NAME=`echo "$TYPE" | cut -d ":" -f 2`
else
    NAME=$TYPE
fi

DOWNLOAD()
{
    URL="$1"
    ZIP_NAME="update.zip"
    mkdir -p "$PROJECT_DIR/tmp"
    echo "-> Downloading firmware..."
    if echo "${URL}" | grep -q "mega.nz\|mediafire.com\|drive.google.com"; then
        ("${DL}" "${URL}" "$PROJECT_DIR/tmp" "$ZIP_NAME") || exit 1
    else
        if echo "${URL}" | grep -q "1drv.ms"; then URL=${URL/ms/ws}; fi
        { type -p aria2c > /dev/null 2>&1 && aria2c -x16 -j$(nproc) -U "Mozilla/5.0" -d "$PROJECT_DIR/input" -o "$ACTUAL_ZIP_NAME" ${URL} > /dev/null 2>&1; } || { wget -U "Mozilla/5.0" ${URL} -O "$PROJECT_DIR/input/$ACTUAL_ZIP_NAME" > /dev/null 2>&1 || exit 1; }
        aria2c -x16 -j$(nproc) -U "Mozilla/5.0" -d "$PROJECT_DIR/tmp" -o "$ACTUAL_ZIP_NAME" ${URL} > /dev/null 2>&1 || {
            wget -U "Mozilla/5.0" ${URL} -O "$PROJECT_DIR/tmp/$ACTUAL_ZIP_NAME" > /dev/null 2>&1 || exit 1
        }
    fi
}
ZIP_NAME="$PROJECT_DIR/tmp/dummy"
    if [[ "$URL" == "http"* ]]; then
        # URL detected
        ACTUAL_ZIP_NAME=update.zip
        ZIP_NAME="$PROJECT_DIR"/tmp/update.zip
        DOWNLOAD "$URL" "$ZIP_NAME"
        URL="$ZIP_NAME"
    fi
echo "zip_file: $(ls "$PROJECT_DIR"/tmp)" || exit 1
   "$PROJECT_DIR"/make.sh --AB Generic update.zip --fix-bug

sudo rm -rf "$PROJECT_DIR/output/Guide.txt"
sudo rm -rf "$PROJECT_DIR/output/Patch3.zip"
sudo rm -rf "$PROJECT_DIR/workspace"
sudo rm -rf "$PROJECT_DIR/output/makemesar.zip"
sudo mv "$PROJECT_DIR/output/system.img" "$PROJECT_DIR/output/$NAME-AB-RK137SGSI.img"
ls "$PROJECT_DIR"/output || exit 1
echo "-> Porting SGSI done!"
