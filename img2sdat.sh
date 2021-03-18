#!/bin/bash

# Copyright (C) 2020 Xiaoxindada <2245062854@qq.com>

LOCALDIR=`cd "$( dirname $0 )" && pwd`
cd $LOCALDIR
source ./bin.sh

echo "请确保img在工具根目录"

read -p "请输入你要制造的img名(不要带.img): " img

if [ $(file ./$img'.img' | grep -o 'data') ];then
  echo "正在转换simg......"
  $bin/img2simg $img'.img' $img's.img'
  echo "转换完成"
else
  mv ./$img'.img' ./$img's.img'
fi
mv ./$img's.img' ./bin/img2sdat/
cd ./bin/img2sdat
rm -rf ./output
mkdir ./output
echo "正在生成new.dat......"
python3 ./img2sdat.py $img's.img' -o output -v 4 -p $img
echo "已生成......"
echo "正在移动至输出目录....."
cd ../../
rm -rf ./new_dat
mkdir ./new_dat
mv $bin/img2sdat/output/* ./new_dat/
echo "dat已输出至new_dat文件夹"
if [ $(file $bin/img2sdat/$img's.img' | grep -o 'sparse') ];then
  mv $bin/img2sdat/$img's.img' $bin/img2sdat/$img'.img'
  mv $bin/img2sdat/$img'.img' ./
else
  rm -rf $bin/img2sdat/$img's.img'
fi

read -p "是否制造$img.dat.br(y/n): " br

if [ $br = "y" ];then
  echo "正在生成$img.new.br....."
  $bin/brotli -q 0 ./new_dat/$img.new.dat -o ./new_dat/$img.new.dat.br
  echo "已生成"
else
  echo "不生成$img.new.br"
fi
