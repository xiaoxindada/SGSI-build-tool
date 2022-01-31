#!/bin/bash

# Copyright (C) 2021 Xiaoxindada <2245062854@qq.com>

LOCALDIR=`cd "$( dirname ${BASH_SOURCE[0]} )" && pwd`
cd $LOCALDIR
source ./bin.sh

if [ ! -e $LOCALDIR/dtbo.img ];then
  echo "dtbo.img does not exist！"
  exit 1
fi
dtc="$bin/dtb_tools/dtc"
mkdtimg_tool="$bin/dtb_tools/mkdtboimg.py"
dtbodir="$LOCALDIR/dtbo"

rm -rf $dtbodir
mkdir -p $dtbodir/dtbo_files
mkdir -p $dtbodir/dts_files

echo "decompressing dtbo.img"
$mkdtimg_tool dump "$LOCALDIR/dtbo.img" -b "$dtbodir/dtbo_files/dtbo" > $dtbodir/dtbo_imageinfo.txt

dtbo_files_name=$(ls $dtbodir/dtbo_files)
for dtbo_files in $dtbo_files_name ;do
  dts_files=$(echo "$dtbo_files" | sed 's/dtbo/dts/g')
  echo "decompiling $dtbo_files for $dts_files"
  $dtc -@ -I "dtb" -O "dts" "$dtbodir/dtbo_files/$dtbo_files" -o "$dtbodir/dts_files/$dts_files" > /dev/null 2>&1
  [ $? != 0 ] && echo "decompile $dtbo_files Fail" && exit 1
done
echo "The decompression is complete, and it has been output to $dtbodir"
chmod 777 -R $dtbodir
