#!/bin/bash

# Copyright (C) 2020 Xiaoxindada <2245062854@qq.com>

source ./bin.sh
LOCALDIR=`cd "$( dirname $0 )" && pwd`
cd $LOCALDIR

rm -rf ./images
echo ""
read -p "请输入要打包的分区(别带.img): " species

echo "
开始打包

当前img大小为: 

_________________

`du -sh ./out/$species | awk '{print $1}'`

`du -sm ./out/$species | awk '{print $1}' | sed 's/$/&M/'`

`du -sb ./out/$species | awk '{print $1}' | sed 's/$/&B/'`
_________________

使用G为单位打包时必须带单位且为整数
使用B为单位打包时无需带单位且在自动识别的大小添加一定大小
推荐用M为单位大小进行打包需带单位且在自动识别的大小添加至少130M大小
"

read -p "请输入要打包的数值: " size

M="$(echo "$size" | sed 's/M//g')"
G="$(echo "$size" | sed 's/G//g')"

if [ $(echo "$size" | grep 'M') ];then
  ssize=$(($M*1024*1024))
elif [ $(echo "$size" | grep 'G') ];then
  ssize=$(($G*1024*1024*1024))
else
  ssize=$size
fi

if [ $species = "system" ];then
  $bin/mkuserimg_mke2fs.sh "./out/$species/" "./out/${species}.img" "ext4" "/$species" "$ssize" -j "0" -T "1230768000" -C "./out/config/${species}_fs_config" -L "$species" -I "256" -M "/$species" -m "0" "./out/config/${species}_file_contexts"
else  
  $bin/mkuserimg_mke2fs.sh "./out/$species/" "./out/${species}.img" "ext4" "/$species" "$ssize" -j "0" -T "1230768000" -C "./out/config/${species}_fs_config" -L "$species" -I "256" -M "/$species" -m "0" "./out/config/${species}_file_contexts"
fi

if [ -s ./out/$species.img ];then
  echo "打包完成"
  echo "输出至images文件夹"
  rm -rf ./images
  mkdir ./images
  mv ./out/$species.img ./images
  chmod 777 -R ./images
else
  echo "打包失败，错误日志如上"
fi
