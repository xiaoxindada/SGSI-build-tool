#!/bin/bash

# Copyright (C) 2020 Xiaoxindada <2245062854@qq.com>

LOCALDIR=`cd "$( dirname ${BASH_SOURCE[0]} )" && pwd`
cd $LOCALDIR
source ./bin.sh

function Usage() {
cat <<EOT
Usage:
$0 <Image Path> [Other args]
  Image Path: Image Path
  
  Other args:
    [--make_br]: Make new.dat.br
EOT
}

case $1 in
  "-h"|"--help")
    Usage
    exit
    ;;   
esac

if [ "$1" = "" ];then
  Usage
  exit
fi

image="$1"
image_name=$(echo ${image##*/} | sed 's/\.img//')
make_br="false"

[ ! -e $image ] && echo "$image 不存在！" && exit

function img2simg() {
  rimg_file="$image"
  simg_file=$(echo "${image%%.*}" | sed 's/$/&s\.img/')
  echo "正在转换simg..."
  $bin/img2simg "$rimg_file" "$simg_file"
  if [ $? != "0" ];then
    echo "转换失败"
  else
    echo "转换成功"
    mv -f $simg_file $bin/img2sdat/${image_name}.img
  fi
}

function simg2sdat() {
  if [ ! -f $bin/img2sdat/${image_name}.img ];then
    cp -frp $image $bin/img2sdat/${image_name}.img
  fi
  cd $bin/img2sdat
  rm -rf ./output
  mkdir ./output
  file ${image_name}.img
  echo "正在生成 ${image_name}.new.dat..."
  python3 ./img2sdat.py "${image_name}.img" -o "output" -v "4" -p "$image_name"
  if [ $? != "0" ];then
    echo "转换失败！"
    rm -rf ${image_name}.img
    exit
  else
    echo "${image_name}.new.dat 已生成..."
    rm -rf ${image_name}.img
    echo "正在移动至输出目录..."
    cd $LOCALDIR
    rm -rf ./new_dat
    mkdir ./new_dat
    mv $bin/img2sdat/output/* ./new_dat/
    echo "输出至 $LOCALDIR/new_dat 文件夹"
  fi
}

function sdat2sdat_br() {
  echo "正在生成 ${image_name}.new.dat.br..."
  $bin/brotli -q 0 $LOCALDIR/new_dat/${image_name}.new.dat -o $LOCALDIR/new_dat/${image_name}.new.dat.br
  if [ $? != "0" ] ;then 
    echo "${image_name}.new.dat.br 生成失败！"
    exit
   else
    echo "${image_name}.new.dat.br 已生成"
    echo "输出至$LOCALDIR/new_dat/${image_name}.new.dat.br"
  fi
}

if ! (file $image | grep -qo "sparse") ;then
  img2simg
fi

simg2sdat

if [ "$2" = "--make_br" ];then
  make_br="true"
fi

if [ $make_br = "true" ];then
  sdat2sdat_br
fi
