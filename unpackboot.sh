#!/bin/bash

LOCALDIR=`cd "$( dirname $0 )" && pwd`
cd $LOCALDIR
source ./bin.sh

bb=busybox
aik=$bin/boot_tools/AIK
boot_img=$LOCALDIR/boot.img
bootdir=$LOCALDIR/boot

rm -rf $bootdir
mkdir -p $bootdir

[ ! -e $boot_img ] && echo "boot.img 不存在！" && exit 1
cp -frp $boot_img $aik/
cd $aik
./unpackimg.sh $(basename $boot_img)
if [ $? = "0" ];then
  rm -rf $(basename $boot_img)
  mv ./ramdisk $bootdir
  mv ./split_img $bootdir
else
  echo -e "\033[33m 方案一解压失败，开始尝试第二种解压方案 \033[0m"
  rm -rf $(basename $boot_img)
  ./cleanup.sh
  cd $LOCALDIR
  ./unpackboot_test.sh
  [ $? != "0" ] && echo "解压失败" && exit
fi
cd $LOCALDIR
chmod 777 -R $bootdir
