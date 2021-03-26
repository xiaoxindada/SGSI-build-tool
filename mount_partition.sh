#!/bin/bash

LOCALDIR=`cd "$( dirname $0 )" && pwd`
cd $LOCALDIR
source ./bin.sh

rm -rf ./out
rm -rf ./SGSI
mkdir ./out

systemdir="$LOCALDIR/out/system/system"
partition_list="system_ext product"

for partition in system ;do
  umount $partition 2>/dev/null
  rm -rf $partition
  mkdir -p $partition
  mkdir -p $LOCALDIR/out/$partition
  mount -o ro $partition.img $partition
  echo "正在复制 $partition 至 $LOCALDIR/out/$partition"
  ( cd $LOCALDIR/$partition ; tar cf - . ) | ( cd "$LOCALDIR/out/$partition" ; tar xf - ; cd $LOCALDIR )
  umount $LOCALDIR/$partition 
  rm -rf $LOCALDIR/$partition
done

if [ -e $LOCALDIR/vendor.img ];then
  for partition in vendor ;do
    umount $partition 2>/dev/null
    rm -rf $partition
    mkdir -p $partition
    mkdir -p $LOCALDIR/out/$partition
    mount -o ro $partition.img $partition
    echo "正在复制 $partition 至 $LOCALDIR/out/$partition"
    ( cd $LOCALDIR/$partition; tar cf - . ) | ( cd $LOCALDIR/out/$partition ; tar xf - ; cd $LOCALDIR)
    umount $LOCALDIR/$partition
    rm -rf $LOCALDIR/$partition
  done
fi

[ ! -d $systemdir ] && echo "${systemdir}不存在！" && exit

if [[ -d $systemdir/../system_ext && -L $systemdir/system_ext ]] \
|| [[ -d $systemdir/../product && -L $systemdir/product ]];then
  echo "检测到当前为动态分区"
fi

for partition in $partition_list ;do
  if [ -e $LOCALDIR/${partition}.img ];then
    [ -d $systemdir/$partition ] && continue   
    umount $partition 2>/dev/null
    rm -rf $partition
    rm -rf $systemdir/$partition
    mkdir -p $partition
    mkdir -p $systemdir/$partition
    mount -o ro $partition.img $partition
    echo "正在复制 $partition 至 $systemdir/$partition"
    ( cd $LOCALDIR/$partition; tar cf - . ) | ( cd $systemdir/$partition ; tar xf - ; cd $LOCALDIR)
    umount $LOCALDIR/$partition
    rm -rf $LOCALDIR/$partition
  fi
done
