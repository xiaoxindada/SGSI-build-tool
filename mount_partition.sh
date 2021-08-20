#!/bin/bash

LOCALDIR=`cd "$( dirname ${BASH_SOURCE[0]} )" && pwd`
cd $LOCALDIR
source ./bin.sh
source ./language_helper.sh

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
  echo "$COPING_STR $partition $TO_STR $LOCALDIR/out/$partition"
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
    echo "$COPING_STR $partition $TO_STR $LOCALDIR/out/$partition"
    ( cd $LOCALDIR/$partition; tar cf - . ) | ( cd $LOCALDIR/out/$partition ; tar xf - ; cd $LOCALDIR)
    umount $LOCALDIR/$partition
    rm -rf $LOCALDIR/$partition
  done
fi

[ ! -d $systemdir ] && echo "${systemdir} $NOTFOUND_STR！" && exit

if [[ -d $systemdir/../system_ext && -L $systemdir/system_ext ]] \
|| [[ -d $systemdir/../product && -L $systemdir/product ]];then
  echo "$DYNAMIC_PARTITION_DETECTED"
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
    echo "$COPING_STR $partition $TO_STR $systemdir/$partition"
    ( cd $LOCALDIR/$partition; tar cf - . ) | ( cd $systemdir/$partition ; tar xf - ; cd $LOCALDIR)
    umount $LOCALDIR/$partition
    rm -rf $LOCALDIR/$partition
  fi
done
