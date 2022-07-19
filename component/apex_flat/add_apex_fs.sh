#!/bin/bash

# Copyright (C) 2020 Xiaoxindada <2245062854@qq.com>

LOCALDIR=`cd "$( dirname ${BASH_SOURCE[0]} )" && pwd`
cd $LOCALDIR
source $LOCALDIR/../../bin.sh
source $LOCALDIR/../../language_helper.sh

configdir="$TARGETDIR/config"
echo "add_apex_fs"

# add_fs
rm -rf $TARGETDIR/apex_fs
mkdir $TARGETDIR/apex_fs

contexts="$TARGETDIR/apex_fs/apex_contexts"
bin_fs="$TARGETDIR/apex_fs/apex_bin_fs"
lib_fs="$TARGETDIR/apex_fs/apex_lib_fs"
fs="$TARGETDIR/apex_fs/apex_fs"

files=$(find $TARGETDIR/system/system/apex/ -name '*')
for file in $files ;do
  if [ -d "$file" ];then
    echo "$file" | sed "s|$TARGETDIR/system/system/|system/system/|g" | sed 's/$/& 0 0 0755/g' >>$fs
    if [ $(echo "$file" | grep -E "\/lib|\/lib64") ];then
      echo "$file" | sed "s|$TARGETDIR/system/system/|/system/system/|g" | sed 's/$/& u:object_r:system_lib_file:s0/g' >>$contexts
    else
      echo "$file" | sed "s|$TARGETDIR/system/system/|/system/system/|g" | sed 's/$/& u:object_r:system_file:s0/g' >>$contexts
    fi 
  fi

  if [ -L "$file" ];then
    echo "$file" | sed "s|$TARGETDIR/system/system/|system/system/|g" | sed 's/$/& 0 0 0644/g' >>$fs
    if [ $(echo "$file" | grep ".so$") ];then
      echo "$file" | sed "s|$TARGETDIR/system/system/|/system/system/|g" | sed 's/$/& u:object_r:system_lib_file:s0/g' >>$contexts
    else
      echo "$file" | sed "s|$TARGETDIR/system/system/|/system/system/|g" | sed 's/$/& u:object_r:system_file:s0/g' >>$contexts
    fi
  fi

  if [ -f "$file" ];then
    echo "$file" | sed "s|$TARGETDIR/system/system/|system/system/|g" | sed 's/$/& 0 0 0644/g' >>$fs
    if [ $(echo "$file" | grep ".so$") ];then
      echo "$file" | grep ".so$" | sed "s|$TARGETDIR/system/system/|/system/system/|g" | sed 's/$/& u:object_r:system_lib_file:s0/g' >>$contexts
    else
      echo "$file" | sed "s|$TARGETDIR/system/system/|/system/system/|g" | sed 's/$/& u:object_r:system_file:s0/g' >>$contexts
    fi
  fi 
done

if [[ -d $TARGETDIR/system/system/system_ext/apex/ ]];then
files=$(find $TARGETDIR/system/system/system_ext/apex/ -name '*')
for file in $files ;do
  if [ -d "$file" ];then
    echo "$file" | sed "s|$TARGETDIR/system/system/system_ext/|system/system/system_ext/|g" | sed 's/$/& 0 0 0755/g' >>$fs
    if [ $(echo "$file" | grep -E "\/lib|\/lib64") ];then
      echo "$file" | sed "s|$TARGETDIR/system/system/system_ext/|/system/system/system_ext/|g" | sed 's/$/& u:object_r:system_lib_file:s0/g' >>$contexts
    else
      echo "$file" | sed "s|$TARGETDIR/system/system/system_ext/|/system/system/system_ext/|g" | sed 's/$/& u:object_r:system_file:s0/g' >>$contexts
    fi 
  fi

  if [ -L "$file" ];then
    echo "$file" | sed "s|$TARGETDIR/system/system/system_ext/|system/system/system_ext/|g" | sed 's/$/& 0 0 0644/g' >>$fs
    if [ $(echo "$file" | grep ".so$") ];then
      echo "$file" | sed "s|$TARGETDIR/system/system/system_ext/|/system/system/system_ext/|g" | sed 's/$/& u:object_r:system_lib_file:s0/g' >>$contexts
    else
      echo "$file" | sed "s|$TARGETDIR/system/system/system_ext/|/system/system/system_ext/|g" | sed 's/$/& u:object_r:system_file:s0/g' >>$contexts
    fi
  fi

  if [ -f "$file" ];then
    echo "$file" | sed "s|$TARGETDIR/system/system/system_ext/|system/system/system_ext/|g" | sed 's/$/& 0 0 0644/g' >>$fs
  if [ $(echo "$file" | grep ".so$") ];then
    echo "$file" | grep ".so$" | sed "s|$TARGETDIR/system/system/system_ext/|/system/system/system_ext/|g" | sed 's/$/& u:object_r:system_lib_file:s0/g' >>$contexts
  else
    echo "$file" | sed "s|$TARGETDIR/system/system/system_ext/|/system/system/system_ext/|g" | sed 's/$/& u:object_r:system_file:s0/g' >>$contexts
    fi
  fi 
done
fi

sed -i '/\/system\/system\/apex/d' $configdir/system_file_contexts
sed -i '/system\/system\/apex/d' $configdir/system_fs_config

# contexts
sed -i '1d' $contexts
echo "/system/system/apex u:object_r:system_file:s0" >> $contexts
echo "/system/system/sysem_ext/apex u:object_r:system_file:s0" >> $contexts
for file in $contexts ;do
  sed -i \
    -e 's|\.|\\.|g' \
    -e 's|\+|\\+|g' \
    $file
done

# fs
sed -i '1d' $fs
echo "system/system/apex 0 0 0755" >> $fs
echo "system/system/system_ext/apex 0 0 0755" >> $fs
cat $fs | grep "bin" >> $bin_fs
sed -i '/bin/d' $fs
sed -i 's/bin 0 0 0755/bin 0 2000 0751/g' $bin_fs
sed -i 's/ 0 0 0644/ 0 2000 0755/g' $bin_fs
sed -i 's/ 0 0 0755/ 0 2000 0755/g' $bin_fs
cat $bin_fs | grep ".so 0 2000 0755" >> $lib_fs
sed -i '/\.so 0 2000 0755/d' $bin_fs
sed -i 's/\.so 0 2000 0755/\.so 0 0 0644/g' $lib_fs
cat $bin_fs >> $fs
cat $lib_fs >> $fs

cat $fs >> $configdir/system_fs_config
cat $contexts >> $configdir/system_file_contexts
