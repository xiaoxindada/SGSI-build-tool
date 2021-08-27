#!/bin/bash
 
# Copyright (C) 2021 Xiaoxindada <2245062854@qq.com>
 
LOCALDIR=`cd "$( dirname ${BASH_SOURCE[0]} )" && pwd`
cd $LOCALDIR
source ./bin.sh
source ./language_helper.sh

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
  echo "$MERGING_STR ${partition} $PARTITION_STR"

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
      contexts_header=$(grep -n -o -E "^/ u:" $dynamic_fs_dir/$i | head -n 1 | grep -o -E "^[0-9]+")
      [ -n "$contexts_header" ] && sed -i "${contexts_header}d" $dynamic_fs_dir/$i
      sed -i '/\?/d' $dynamic_fs_dir/$i
      sed -i "/system\/${partition} /d" $target_contexts
      echo -e "\n" >> $target_contexts
      echo "/system/${partition} u:object_r:system_file:s0" >> $target_contexts
      sed -i "s/^/&\/system\/system/g" $dynamic_fs_dir/$i
      cat $dynamic_fs_dir/$i >> $dynamic_fs_dir/${partition}_merge_contexts
      cat $dynamic_fs_dir/${partition}_merge_contexts >> $target_contexts
    fi
  done

  for i in $(ls $dynamic_fs_dir | grep "${partition}_fs_config$");do
    if [ -e $dynamic_fs_dir/$i ];then
      config_header=$(grep -n -o -E "^/ 0" $dynamic_fs_dir/$i | head -n 1 | grep -o -E "^[0-9]+")
      [ -n "$config_header" ] && sed -i "${config_header}d" $dynamic_fs_dir/$i
      sed -i "/system\/${partition} /d" $target_fs
      echo -e "\n" >> $target_fs
      echo "system/${partition} 0 0 0644 /system/${partition}" >> $target_fs      
      sed -i "s/^/&system\/system\//g" $dynamic_fs_dir/$i
      cat $dynamic_fs_dir/$i >> $dynamic_fs_dir/${partition}_merge_fs_config
      cat $dynamic_fs_dir/${partition}_merge_fs_config >> $target_fs
    fi
  done
  echo "$MERGE_SUCCESS"
done
