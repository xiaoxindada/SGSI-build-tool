#!/bin/bash

LOCALDIR=`cd "$( dirname ${BASH_SOURCE[0]} )" && pwd`
cd $LOCALDIR
source ./bin.sh

rm -rf $LOCALDIR/${species}.img
read -p "请输入要打包的分区(别带.img): " species
$bin/mkerofsimage.sh "./out/${species}" "./out/${species}.img" -m "/${species}" -C "./out/config/${species}_fs_config" -c "./out/config/${species}_file_contexts" -z "lz4" -T "1230768000"
if [ -s ./out/$species.img ];then
  echo "打包完成"
  echo "输出至images文件夹"
  mkdir -p ./images
  mv -f ./out/$species.img ./images
  chmod 777 -R ./images
else
  echo "打包失败，错误日志如上"
fi
