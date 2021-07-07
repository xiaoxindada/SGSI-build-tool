#!/bin/bash
 
# Copyright (C) 2021 Xiaoxindada <2245062854@qq.com>
 
LOCALDIR=`cd "$( dirname $0 )" && pwd`
cd $LOCALDIR
source ./bin.sh

systemdir="$TARGETDIR/system/system"
configdir="$TARGETDIR/config"
dynamic_fs_dir="$TARGETDIR/dynamic_fs"
target_fs="$configdir/system_fs_config"
target_contexts="$configdir/system_file_contexts"
partition_name="product system_ext"

rm -rf $TARGETDIR/dynamic_fs
mkdir -p $TARGETDIR/dynamic_fs

for partition in $partition_name ;do
  [ -d $systemdir/$partition ] && continue
  echo "正在合并${partition}分区"

  if [ -d $TARGETDIR/$partition ];then
    rm -rf $systemdir/$partition
    rm -rf $TARGETDIR/$partition/lost+found
    mv $TARGETDIR/$partition $systemdir/
    rm -rf "$systemdir/../$partition"
    ln -s "/system/$partition" "$systemdir/../$partition"
  fi
  
  if [ -f $configdir/${partition}_file_contexts ];then
    cp -frp $configdir/${partition}_file_contexts $dynamic_fs_dir/
  fi

  if [ -f $configdir/${partition}_fs_config ];then
    cp -frp $configdir/${partition}_fs_config $dynamic_fs_dir/
  fi

  for i in $(ls $dynamic_fs_dir | grep "${partition}_file_contexts$");do
    if [ -e $dynamic_fs_dir/$i ];then
      sed -i '1d' $dynamic_fs_dir/$i
      sed -i '/\?/d' $dynamic_fs_dir/$i
      sed -i "/system\/${partition} /d" $target_contexts
      echo "/system/${partition} u:object_r:system_file:s0" >> $target_contexts
      sed -i "s/^/&\/system\/system/g" $dynamic_fs_dir/$i
      cat $dynamic_fs_dir/$i >> $dynamic_fs_dir/${partition}_merge_contexts
      cat $dynamic_fs_dir/${partition}_merge_contexts >> $target_contexts
    fi
  done

  for i in $(ls $dynamic_fs_dir | grep "${partition}_fs_config$");do
    if [ -e $dynamic_fs_dir/$i ];then
      sed -i '1d' $dynamic_fs_dir/$i
      sed -i "/system\/${partition} /d" $target_fs
      echo "system/${partition} 0 0 0644 /system/${partition}" >> $target_fs      
      sed -i "s/^/&system\/system\//g" $dynamic_fs_dir/$i
      cat $dynamic_fs_dir/$i >> $dynamic_fs_dir/${partition}_merge_fs_config
      cat $dynamic_fs_dir/${partition}_merge_fs_config >> $target_fs
    fi
  done
  echo "合并完成"
done
