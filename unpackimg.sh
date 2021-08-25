#!/bin/bash

# Copyright (C) 2020 Xiaoxindada <2245062854@qq.com>

LOCALDIR=`cd "$( dirname ${BASH_SOURCE[0]} )" && pwd`
cd $LOCALDIR
source ./bin.sh

rm -rf ./out
mkdir ./out

echo ""
read -p "请输入要接包的分区(别带.img): " species

echo "正在解压$species..."
if ! python3 $bin/imgextractor.py ./$species'.img' ./out ;then
  echo "正在尝试使用erofs解压"
  if ! $bin/erofsUnpackKt $species'.img' ./out 2&>/dev/null ;then
    echo "$species'.img 解压失败！"
  fi
fi

