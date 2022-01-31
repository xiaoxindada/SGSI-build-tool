#!/bin/bash

# Copyright (C) 2020 Xiaoxindada <2245062854@qq.com>

LOCALDIR=`cd "$( dirname ${BASH_SOURCE[0]} )" && pwd`
cd $LOCALDIR
source ./bin.sh

EROFS_MAGIC_V1="e2e1f5e0" # 0xE0F5E1E2
EXT_MAGIC="53ef" # 0xEF53
EXT_OFFEST="1080"
EROFS_OFFEST="1024"

rm -rf $LOCALDIR/out
mkdir $LOCALDIR/out

echo ""
read -p "Please enter the partition to receive the package (don't bring .img): " species
if [ $(xxd -p -l "2" --skip "$EXT_OFFEST" "${species}.img") = "$EXT_MAGIC" ];then
  echo "Detected ${species}.img as ext2/3/4 filesystem"
  echo "Extracting ${species}.img..."
  python3 $bin/imgextractor.py ${species}.img $LOCALDIR/out
  [ $? != 0 ] && echo "Failed to decompress ${species}.img Fail" && exit 1
elif [ $(xxd -p -l "4" --skip "$EROFS_OFFEST" "${species}.img") = "$EROFS_MAGIC_V1" ];then
  echo "Detected ${species}.img as erofs filesystem"
  echo "Extracting ${species}.img..."
  $bin/erofsUnpackKt ${species}.img $LOCALDIR/out 
  [ $? != 0 ] && echo "Failed to decompress ${species}.img Fail" && exit 1
fi
