#!/bin/bash

LOCALDIR=`cd "$( dirname $0 )" && pwd`
cd $LOCALDIR

case $1 in
  "official") 
    echo "正在解压apex中....."
    ./apex_extractor.sh "$LOCALDIR/../../out/system/system/apex"
    ;;
  "unofficial")
    echo "正在解压apex中....."
    ./apex_extractor2.sh "$LOCALDIR/../../out/system/system/apex"
    ;;
esac 
