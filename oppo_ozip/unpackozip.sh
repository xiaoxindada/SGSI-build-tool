#!/bin/bash

LOCALDIR=`cd "$( dirname $0 )" && pwd`
cd $LOCALDIR

ozip_name=$(ls | grep ".ozip$")
for ozip in $ozip_name ;do
  python3 ./ozipdecrypt.py $ozip
done
