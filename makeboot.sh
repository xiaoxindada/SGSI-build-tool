#!/bin/bash

LOCALDIR=`cd "$( dirname $0 )" && pwd`
cd $LOCALDIR
source ./bin.sh

AIK="$bin/boot_tools/AIK"

echo "正在生成new-boot.img..."
mv ./boot/* $AIK
cd $AIK
./repackimg.sh --forceelf #--origsize
if [ -e ./unpadded-new.img ];then
  mv ./unpadded-new.img $LOCALDIR/boot/
fi
mv ./image-new.img ./boot-new.img
mv ./boot-new.img $LOCALDIR/boot/
rm -rf ./split_img
rm -rf ./ramdisk
rm -rf ./boot.img
if [ -e $(pwd)/ramdisk-new.cpio.gz ]; then
  rm -rf $(pwd)/ramdisk-new.cpio.gz
fi
cd $LOCALDIR
chmod 777 -R ./boot
echo "生成完毕，输出至boot目录"
