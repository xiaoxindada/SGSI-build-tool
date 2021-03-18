#!/bin/bash

LOCALDIR=`cd "$( dirname $0 )" && pwd`
cd $LOCALDIR
source ./bin.sh

rm -rf ./super
mkdir ./super
file $(find -type f -name 'super.img') > ./file.txt
echo "识别到$(find ./ -type f -name 'super.img')"

if [ $(grep -o 'sparse' ./file.txt) ];then
 echo "当前super.img转换为rimg中......"
 $bin/simg2img $(find ./ -type f -name 'super.img') ./superr.img
 echo "转换完成"
 echo "解压super.img中....."
 $bin/lpunpack ./superr.img ./super
 rm -rf ./superr.img
 chmod 777 -R ./super
 echo "解压完成"
fi

if [ $(grep -o 'data' ./file.txt) ];then
  echo "解压super.img中....."
  $bin/lpunpack $(find ./ -type f -name 'super.img') ./super
  #rm -rf ./super.img
  chmod 777 -R ./super
  echo "解压完成" 
fi

rm -rf ./file.txt
