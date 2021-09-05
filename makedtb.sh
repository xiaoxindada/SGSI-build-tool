#!/bin/bash

# Copyright (C) 2021 Xiaoxindada <2245062854@qq.com>

LOCALDIR=`cd "$( dirname ${BASH_SOURCE[0]} )" && pwd`
cd $LOCALDIR
source ./bin.sh

dtc="$bin/dtb_tools/dtc"
dtbdir="$LOCALDIR/dtbs"

rm -rf $dtbdir/new_dtb_files
rm -rf $dtbdir/output_dtb
mkdir -p $dtbdir/new_dtb_files
mkdir -p $dtbdir/output_dtb

dts_files_name=$(ls $dtbdir/dts_files)
for dts_files in $dts_files_name ;do
  new_dtb_files=$(echo "$dts_files" | sed 's/dts/dtb/g')
  echo "正在回编译$dts_files为$new_dtb_files"
  $dtc -@ -I "dts" -O "dtb" "$dtbdir/dts_files/$dts_files" -o "$dtbdir/new_dtb_files/$new_dtb_files" > /dev/null 2>&1
  [ $? != 0 ] && echo "回编译dtb失败" && exit 1
done
find $dtbdir/new_dtb_files -name "dtb*" -exec cat {} > $dtbdir/output_dtb/dtb \;
echo "回编译完成，已输出至 $dtbdir/output_dtb"
chmod 777 -R $dtbdir
