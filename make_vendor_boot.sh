#!/bin/bash

# Copyright (C) 2021 Xiaoxindada <2245062854@qq.com>

LOCALDIR=`cd "$( dirname ${BASH_SOURCE[0]} )" && pwd`
cd $LOCALDIR
source ./bin.sh

bb=busybox
aik=$bin/boot_tools/AIK
vendor_bootdir=$LOCALDIR/vendor_boot

[ ! -d $vendor_bootdir/split_img ] && echo "此解包方法暂不支持重新打包" && exit 1
mv $vendor_bootdir/* $aik
cd $aik
./repackimg.sh --forceelf #--origsize
if [ -f ./unpadded-new.img ];then
  mv ./unpadded-new.img $vendor_bootdir/
fi
mv ./image-new.img ./vendor_boot-new.img
mv ./vendor_boot-new.img $vendor_bootdir/
./cleanup.sh
if [ -f $vendor_bootdir/vendor_boot-new.img ];then
echo "文件以输出至 $vendor_bootdir 目录"
fi
chmod 777 -R $vendor_bootdir
