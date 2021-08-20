#!/bin/bash

LOCALDIR=`cd "$( dirname ${BASH_SOURCE[0]} )" && pwd`
cd $LOCALDIR
source ./bin.sh

aik=$bin/boot_tools/AIK
bootdir=$LOCALDIR/boot

[ ! -d $bootdir/split_img ] && echo "此解包方法暂不支持重新打包" && exit 1
mv $bootdir/* $aik
cd $aik
./repackimg.sh --forceelf #--origsize
if [ -f ./unpadded-new.img ];then
  mv ./unpadded-new.img $LOCALDIR/boot/
fi
mv ./image-new.img ./boot-new.img
mv ./boot-new.img $LOCALDIR/boot/
./cleanup.sh
cd $LOCALDIR
if [ -f $bootdir/boot-new.img ];then
echo "文件以输出至 $bootdir 目录"
fi
chmod 777 -R $bootdir
