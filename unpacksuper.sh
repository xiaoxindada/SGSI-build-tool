#!/bin/bash

LOCALDIR=`cd "$( dirname $0 )" && pwd`
cd $LOCALDIR
source ./bin.sh

lpunpack="$bin/build_super/lpunpack"

rm -rf ./super
mkdir ./super

[ ! -e ./super.img ] && echo "super.img不存在！" && exit

file ./super.img > ./file.txt

if [ $(grep -o 'sparse' ./file.txt) ];then
  echo "当前super.img转换为rimg中..."
  $bin/simg2img ./super.img ./superr.img
  echo "转换完成"
  super_size=$(du -sb "./superr.img" | awk '{print $1}' | bc -q)
  echo "当前super分区大小为: $super_size bytes"
  echo "解压super.img中..."
  $lpunpack ./superr.img ./super
  if [ $? != "0" ];then
    rm -rf ./superr.img
    echo "解压失败"
    exit
  else
    echo "解压完成"    
  fi
  rm -rf ./superr.img
  chmod 777 -R ./super
fi

if [ $(grep -o 'data' ./file.txt) ];then
  super_size=$(du -sb "./super.img" | awk '{print $1}' | bc -q)
  echo "当前super分区大小为: $super_size bytes"
  echo "解压super.img中..."
  $lpunpack ./super.img ./super
  if [ $? != "0" ];then
    echo "解压失败"
    exit
  else
    echo "解压完成"   
  fi
  chmod 777 -R ./super
fi

rm -rf ./file.txt
