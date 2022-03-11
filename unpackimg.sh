#!/bin/bash

# Copyright (C) 2020 Xiaoxindada <2245062854@qq.com>

LOCALDIR=`cd "$( dirname ${BASH_SOURCE[0]} )" && pwd`
cd $LOCALDIR
source ./bin.sh

EROFS_MAGIC_V1="e2e1f5e0" # 0xE0F5E1E2
EXT_MAGIC="53ef" # 0xEF53
SPARSE_MAGIC="3aff26ed" # 0xed26ff3a
EXT_OFFSET="1080"
EROFS_OFFSET="1024"
SPARSE_OFFSET="0"

rm -rf $LOCALDIR/out
mkdir $LOCALDIR/out

echo ""
read -p "请输入要接包的分区(别带.img): " species
if [ $(xxd -p -l "2" --skip "$EXT_OFFSET" "${species}.img") = "$EXT_MAGIC" ];then
  echo "检测到 ${species}.img 为 ext2/3/4 文件系统"
  echo "正在解压${species}.img..."
  python3 $bin/imgextractor.py ${species}.img $LOCALDIR/out
  [ $? != 0 ] && echo "解压 ${species}.img 失败" && exit 1
elif [ $(xxd -p -l "4" --skip "$SPARSE_OFFSET" "${species}.img") = "$SPARSE_MAGIC" ];then
  echo "检测到 ${species}.img 为 sparse image 正在转化为 raw image..."
  $bin/simg2img ${species}.img ${species}_raw.img
  [ $? != 0 ] && echo "转换 ${species}_raw.img 失败" && exit 1
  mv -f ${species}_raw.img ${species}.img
  echo "正在解压${species}.img..."
  python3 $bin/imgextractor.py ${species}.img $LOCALDIR/out
  [ $? != 0 ] && echo "解压 ${species}.img 失败" && exit 1
elif [ $(xxd -p -l "4" --skip "$EROFS_OFFSET" "${species}.img") = "$EROFS_MAGIC_V1" ];then
  echo "检测到 ${species}.img 为 erofs 文件系统"
  echo "正在解压${species}.img..."
  $bin/erofsUnpackKt ${species}.img $LOCALDIR/out 
  [ $? != 0 ] && echo "解压 ${species}.img 失败" && exit 1
else
  echo "当前img不支持解压 请检查img的文件系统"
  exit 1
fi
