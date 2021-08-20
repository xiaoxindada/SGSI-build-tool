#!/bin/bash

LOCALDIR=`cd "$( dirname ${BASH_SOURCE[0]} )" && pwd`
cd $LOCALDIR
source $LOCALDIR/../bin.sh
source $LOCALDIR/../language_helper.sh

./rm.sh > /dev/null 2>&1

os_type="$1"

echo "
--------------------

$SUPPORTED_ROM_STR:

Pixel
--------------------
"
case "$os_type" in
  "Pixel")
    echo "$FIXING_STR"
    ./pixel.sh
    exit
    ;;
  *)
    echo "$os_type $NOT_SUPPORT_FIX_BUG"
    exit  
    ;;
esac
