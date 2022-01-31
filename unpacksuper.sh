#!/bin/bash

LOCALDIR=`cd "$( dirname ${BASH_SOURCE[0]} )" && pwd`
cd $LOCALDIR
source ./bin.sh

lpunpack="$bin/build_super/lpunpack"

rm -rf ./super
mkdir ./super

[ ! -e ./super.img ] && echo "super.img does not exist！" && exit

file ./super.img > ./file.txt

if [ $(grep -o 'sparse' ./file.txt) ];then
  echo "Convert the current super.img to rimg..."
  $bin/simg2img ./super.img ./superr.img
  echo "conversion completed"
  super_size=$(du -sb "./superr.img" | awk '{print $1}' | bc -q)
  echo "The current super partition size is: $super_size bytes"
  echo "Unzip super.img..."
  $lpunpack ./superr.img ./super
  if [ $? != "0" ];then
    rm -rf ./superr.img
    echo "Unzip failed"
    exit
  else
    echo "Decompression completed"    
  fi
  rm -rf ./superr.img
  chmod 777 -R ./super
fi

if [ $(grep -o 'data' ./file.txt) ];then
  super_size=$(du -sb "./super.img" | awk '{print $1}' | bc -q)
  echo "The current super partition size is: $super_size bytes"
  echo "Unzip super.img..."
  $lpunpack ./super.img ./super
  if [ $? != "0" ];then
    echo "Decompression failed"
    exit
  else
    echo "Decompression complete"   
  fi
  chmod 777 -R ./super
fi

rm -rf ./file.txt
