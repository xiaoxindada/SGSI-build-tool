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
read -p "请输入要接包的分区(别带.img): " species
if [ $(xxd -p -l "2" --skip "$EXT_OFFEST" "${species}.img") = "$EXT_MAGIC" ];then
  echo "检测到 ${species}.img 为 ext2/3/4 文件系统"
  echo "正在解压${species}.img..."
  python3 $bin/imgextractor.py ${species}.img $LOCALDIR/out
  [ $? != 0 ] && echo "解压 ${species}.img 失败" && exit 1
elif [ $(xxd -p -l "4" --skip "$EROFS_OFFEST" "${species}.img") = "$EROFS_MAGIC_V1" ];then
  echo "检测到 ${species}.img 为 erofs 文件系统"
  echo "正在解压${species}.img..."
  $bin/erofsUnpackKt ${species}.img $LOCALDIR/out 
  [ $? != 0 ] && echo "解压 ${species}.img 失败" && exit 1
fi
