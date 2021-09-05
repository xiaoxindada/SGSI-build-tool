#!/bin/bash

# Copyright (C) 2021 Xiaoxindada <2245062854@qq.com>

LOCALDIR=`cd "$( dirname ${BASH_SOURCE[0]} )" && pwd`
cd $LOCALDIR
source ./bin.sh

if [ ! -e $LOCALDIR/dtb ];then
  echo "dtb不存在！"
  exit 1
fi

dtc="$bin/dtb_tools/dtc"
dtbdir="$LOCALDIR/dtbs"

rm -rf $dtbodir
mkdir -p $dtbdir/dts_files

echo "正在反编译dtb"
$dtc -@ -I "dtb" -O "dts" "$LOCALDIR/dtb" -o "$dtbdir/dts_files/dts" > /dev/null 2>&1
[ $? != 0 ] && echo "反编译dtb失败" && exit 1
echo "反编译完成，已输出至 $dtbdir"
chmod 777 -R $dtbdir
