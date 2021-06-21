#/bin/bash

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
  mv ./ramdisk $LOCALDIR/boot/
  mv ./split_img $LOCALDIR/boot/
  cd $LOCALDIR
  chmod 777 -R ./boot
else
  echo "没有boot.img，请重试"
fi
