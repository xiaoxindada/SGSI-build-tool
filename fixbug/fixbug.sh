#!/bin/bash

LOCALDIR=`cd "$( dirname $0 )" && pwd`
cd $LOCALDIR
./rm.sh > /dev/null 2>&1

os_type="$1"

echo "
--------------------

支持的ROM:

Pixel
--------------------
"
case "$os_type" in
  "Pixel")
    echo "正在修复"
    ./pixel.sh
    exit
    ;;
  *)
    echo "$os_type 不支持bug修复"
    exit  
    ;;
esac
