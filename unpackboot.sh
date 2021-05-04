#!/bin/bash

LOCALDIR=`cd "$( dirname $0 )" && pwd`
cd $LOCALDIR
source ./bin.sh

AIK="$bin/boot_tools/AIK"
rm -rf ./boot
mkdir ./boot

if [ -e ./boot.img ];then
  cp -frp ./boot.img $AIK/
  cd $AIK
  ./unpackimg.sh ./boot.img
  if [ $? = "0" ];then
    rm -rf ./boot.img
    mv ./ramdisk $LOCALDIR/boot/
    mv ./split_img $LOCALDIR/boot/
  else
    echo -e "\033[33m 方案一解压失败，开始尝试第二种解压方案 \033[0m"
    rm -rf ./boot.img ./ramdisk ./split_img
    cd $LOCALDIR
    ./unpackboot_test.sh
    [ $? != "0" ] && echo "解压失败" && exit
  fi
  cd $LOCALDIR
  chmod 777 -R ./boot
else
  echo "没有boot.img，请重试"
fi
