#!/bin/bash

# Copyright (C) 2021 Xiaoxindada <2245062854@qq.com>

LOCALDIR=`cd "$( dirname $0 )" && pwd`
cd $LOCALDIR
source ./bin.sh

bb="busybox"
testdir=$bin/boot_tools/test
unpacknootimg=$testdir/unpack_bootimg.py
mkbootimg=$testdir/mkbootimg.py
dumpimage=$testdir/dumpimage
cpio=$testdir/cpio
bootdir=$LOCALDIR/boot
ramdiskdir=$bootdir/ramdisk
kernel_file=$bootdir/kernel
ramdisk_file=$bootdir/ramdisk
rm -rf $bootdir
rm -rf $ramdiskdir
mkdir -p $bootdir

$unpacknootimg --boot_img "$LOCALDIR/boot.img" --out "$bootdir"

[ -f $bootdir/ramdisk* ] && mv -f $bootdir/ramdisk* $bootdir/ramdisk.gz
$bb gunzip -c -k -f "$bootdir/ramdisk.gz" > "$bootdir/ramdisk.img"
mkdir -p $ramdiskdir
cd $ramdiskdir
$cpio -i --no-absolute-filenames < "$bootdir/ramdisk.img"
rm -rf $bootdir/ramdisk.img
chmod 777 -R $bootdir 
cd $LOCALDIR
#cd $ramdiskdir
#find ./ | $cpio -o -H newc > ../ramdisk.img 
#cd $LOCALDIR

