#!/bin/bash

LOCALDIR=`cd "$( dirname $0 )" && pwd`
cd $LOCALDIR

if [ -e ./SGSI/system.img ];then
  ./get_build_info.sh "$LOCALDIR/out/system/system" "$LOCALDIR/SGSI/system.img" > ./SGSI/build_info.txt
fi
cp -frp ./other/* ./SGSI/
chmod 777 -R ./SGSI
