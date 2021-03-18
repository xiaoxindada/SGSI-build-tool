#!/bin/bash

# Copyright (C) 2021 Xiaoxindada <2245062854@qq.com>

LOCALDIR=`cd "$( dirname $0 )" && pwd`
cd $LOCALDIR
source ./bin.sh

if [ ! -e $LOCALDIR/dtbo.img ];then
  echo "dtbo.img不存在！"
  exit
fi

dtbodir="$LOCALDIR/dtbo"

rm -rf $dtbodir
mkdir -p $dtbodir/dtbo_files
mkdir -p $dtbodir/dts_files

echo "正在解压dtbo.img"
$bin/mkdtimg dump "$LOCALDIR/dtbo.img" -b "$dtbodir/dtbo_files/dtbo" > $dtbodir/dtbo_imageinfo.txt

dtbo_files_name=$(ls $dtbodir/dtbo_files)
for dtbo_files in $dtbo_files_name ;do
  dts_files=$(echo "$dtbo_files" | sed 's/dtbo/dts/g')
  echo "正在反编译$dtbo_files为$dts_files"
  $bin/dtc -I "dtb" -O "dts" "$dtbodir/dtbo_files/$dtbo_files" -o "$dtbodir/dts_files/$dts_files" > /dev/null 2>&1
done
echo "解压完成，已输出至$dtbodir目录"
chmod 777 -R $dtbodir
