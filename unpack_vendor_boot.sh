#!/bin/bash

# Copyright (C) 2021 Xiaoxindada <2245062854@qq.com>

LOCALDIR=`cd "$( dirname ${BASH_SOURCE[0]} )" && pwd`
cd $LOCALDIR
source ./bin.sh

bb=busybox
aik=$bin/boot_tools/AIK
vendor_boot_img=$LOCALDIR/vendor_boot.img
testdir=$bin/boot_tools/test
unpacknootimg=$testdir/unpack_bootimg.py
mkbootimg=$testdir/mkbootimg.py
dumpimage=$testdir/dumpimage
cpio=$testdir/cpio
lz4=$testdir/lz4
vendor_bootdir=$LOCALDIR/vendor_boot
vendor_ramdiskdir=$vendor_bootdir/ramdisk

[ ! -e $vendor_boot_img ] && echo "vendor_boot.img 不存在！" && exit 1
rm -rf $vendor_bootdir
mkdir -p $vendor_bootdir

aik_unpack() {
cp -frp $vendor_boot_img $aik
cd $aik
./unpackimg.sh $(basename $vendor_boot_img)
if [ $? = 0 ];then
  mv ./ramdisk $vendor_bootdir
  mv ./split_img $vendor_bootdir
  rm -rf $(basename $vendor_boot_img)
else
  rm -rf $(basename $vendor_boot_img)
  ./cleanup.sh
fi
}

test_unpack() {
rm -rf $vendor_ramdiskdir
mkdir -p $vendor_ramdiskdir
$unpacknootimg --boot_img "$vendor_boot_img" --out "$vendor_bootdir"
if (file $vendor_bootdir/vendor_ramdisk* | grep -qo "lz4") ;then
  $lz4 -d $vendor_bootdir/vendor_ramdisk* $vendor_bootdir/vendor_ramdisk.cpio
  cd $vendor_ramdiskdir
  $cpio -i --no-absolute-filenames < ../vendor_ramdisk.cpio
  rm -rf $vendor_bootdir/vendor_ramdisk.cpio
  cd $LOCALDIR
fi

if (file $vendor_bootdir/vendor_ramdisk* | grep -qo "gz") ;then
  mv $vendor_bootdir/vendor_ramdisk* $vendor_bootdir/vendor_ramdisk.gz
  $bb gunzip -c -k -f $vendor_bootdir/vendor_ramdisk.gz > $vendor_bootdir/vendor_ramdisk.cpio
  cd $vendor_ramdiskdir
  $cpio -i --no-absolute-filenames < ../vendor_ramdisk.cpio
  rm -rf $vendor_bootdir/vendor_ramdisk.cpio
  cd $LOCALDIR
fi
}
aik_unpack || test_unpack
chmod 777 -R $vendor_bootdir
