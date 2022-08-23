#!/bin/bash

# Copyright (C) 2020 Xiaoxindada <2245062854@qq.com>

LOCALDIR=`cd "$( dirname $0 )" && pwd`
cd $LOCALDIR

echo "add_apex_fs"

# add_fs
rm -rf ../apex_fs
mkdir ../apex_fs

contexts="../apex_fs/apex_contexts"
bin_fs="../apex_fs/apex_bin_fs"
lib_fs="../apex_fs/apex_lib_fs"
fs="../apex_fs/apex_fs"

files=$(find ../../out/system/system/apex/ -name '*')
for file in $files ;do
  if [ -d "$file" ];then
    echo "$file" | sed 's#../../out/#/#g' | sed 's/$/& 0 0 0755/g' | sed 's/.//' >>$fs
    if [ $(echo "$file" | grep "lib") ];then
      echo "$file" | sed 's#../../out/#/#g' | sed 's/$/& u:object_r:system_lib_file:s0/g' >>$contexts
    elif [ $(echo "$file" | grep "lib64") ];then
      echo "$file" | sed 's#../../out/#/#g' | sed 's/$/& u:object_r:system_lib_file:s0/g' >>$contexts
    else
      echo "$file" | sed 's#../../out/#/#g' | sed 's/$/& u:object_r:system_file:s0/g' >>$contexts
    fi 
  fi

  if [ -L "$file" ];then
    echo "$file" | sed 's#../../out/#/#g' | sed 's/$/& 0 0 0644/g' | sed 's/.//' >>$fs
    if [ $(echo "$file" | grep ".so$") ];then
      echo "$file" | sed 's#../../out/#/#g' | sed 's/$/& u:object_r:system_lib_file:s0/g' >>$contexts
    else
      echo "$file" | sed 's#../../out/#/#g' | sed 's/$/& u:object_r:system_file:s0/g' >>$contexts
    fi
  fi

  if [ -f "$file" ];then
    echo "$file" | sed 's#../../out/#/#g' | sed 's/$/& 0 0 0644/g' | sed 's/.//' >>$fs
    if [ $(echo "$file" | grep ".so$") ];then
      echo "$file" | grep ".so$" | sed 's#../../out/#/#g' | sed 's/$/& u:object_r:system_lib_file:s0/g' >>$contexts
    else
      echo "$file" | sed 's#../../out/#/#g' | sed 's/$/& u:object_r:system_file:s0/g' >>$contexts
    fi
  fi 
done

if [ -d ../../out/system/system/system_ext/apex ];then
  files=$(find ../../out/system/system/system_ext/apex/ -name '*')
  for file in $files ;do
  if [ -d "$file" ];then
    echo "$file" | sed 's#../../out/#/#g' | sed 's/$/& 0 0 0755/g' | sed 's/.//' >>$fs
    if [ $(echo "$file" | grep "lib") ];then
      echo "$file" | sed 's#../../out/#/#g' | sed 's/$/& u:object_r:system_lib_file:s0/g' >>$contexts
    elif [ $(echo "$file" | grep "lib64") ];then
      echo "$file" | sed 's#../../out/#/#g' | sed 's/$/& u:object_r:system_lib_file:s0/g' >>$contexts
    else
      echo "$file" | sed 's#../../out/#/#g' | sed 's/$/& u:object_r:system_file:s0/g' >>$contexts
    fi 
  fi

  if [ -L "$file" ];then
    echo "$file" | sed 's#../../out/#/#g' | sed 's/$/& 0 0 0644/g' | sed 's/.//' >>$fs
    if [ $(echo "$file" | grep ".so$") ];then
      echo "$file" | sed 's#../../out/#/#g' | sed 's/$/& u:object_r:system_lib_file:s0/g' >>$contexts
    else
      echo "$file" | sed 's#../../out/#/#g' | sed 's/$/& u:object_r:system_file:s0/g' >>$contexts
    fi
  fi

  if [ -f "$file" ];then
    echo "$file" | sed 's#../../out/#/#g' | sed 's/$/& 0 0 0644/g' | sed 's/.//' >>$fs
  if [ $(echo "$file" | grep ".so$") ];then
    echo "$file" | grep ".so$" | sed 's#../../out/#/#g' | sed 's/$/& u:object_r:system_lib_file:s0/g' >>$contexts
  else
    echo "$file" | sed 's#../../out/#/#g' | sed 's/$/& u:object_r:system_file:s0/g' >>$contexts
    fi
  fi 
  done
fi

sed -i '/\/system\/system\/apex/d' ../../out/config/system_file_contexts
sed -i '/system\/system\/apex/d' ../../out/config/system_fs_config

# contexts
sed -i '1d' $contexts
echo "/system/system/apex u:object_r:system_file:s0" >> $contexts
echo "/system/system/sysem_ext/apex u:object_r:system_file:s0" >> $contexts

sed -i '/com.android.adbd\/bin\/adbd /d' $contexts
sed -i '/com.android.art.release\/bin\/dex2oat32 /d' $contexts
sed -i '/com.android.art.release\/bin\/dex2oat64 /d' $contexts
sed -i '/com.android.art.release\/bin\/dexoptanalyzer /d' $contexts
sed -i '/com.android.art.release\/bin\/profman /d' $contexts
sed -i '/com.android.conscrypt\/bin\/boringssl_self_test32 /d' $contexts
sed -i '/com.android.conscrypt\/bin\/boringssl_self_test64 /d' $contexts
sed -i '/com.android.media.swcodec\/bin\/mediaswcodec /d' $contexts
sed -i '/com.android.os.statsd\/bin\/statsd /d' $contexts
sed -i '/com.android.runtime\/bin\/linker /d' $contexts
sed -i '/com.android.runtime\/bin\/linker64 /d' $contexts
sed -i '/com.android.sdkext\/bin\/derive_sdk /d' $contexts
sed -i '/com.android.tzdata\/etc /d' $contexts
sed -i '/com.android.tzdata\/etc\/icu /d' $contexts
sed -i '/com.android.tzdata\/etc\/icu\/icu_tzdata.dat /d' $contexts
sed -i '/com.android.tzdata\/etc\/tz /d' $contexts
sed -i '/com.android.tzdata\/etc\/tz\/tzdata /d' $contexts
sed -i '/com.android.tzdata\/etc\/tz\/telephonylookup.xml /d' $contexts
sed -i '/com.android.tzdata\/etc\/tz\/tz_version /d' $contexts
sed -i '/com.android.tzdata\/etc\/tz\/tzdata /d' $contexts
sed -i '/com.android.tzdata\/etc\/tz\/tzlookup.xml /d' $contexts

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
cat ../add_fs/apex_contexts >> $contexts
cat $fs >> ../../out/config/system_fs_config
cat $contexts >> ../../out/config/system_file_contexts
