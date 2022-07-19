#!/bin/bash

LOCALDIR=`cd "$( dirname ${BASH_SOURCE[0]} )" && pwd`
cd $LOCALDIR

target_fs="$LOCALDIR/add_repack_fs"
target_contexts="$LOCALDIR/add_repack_contexts"

rm -rf $target_fs
rm -rf $target_contexts


for files in $(find ./system/ -name "*");do

  if [ -d $files ];then
    echo $files | sed "s#\./#/#g" | sed "s/^/&\/system/g" | sed "s/$/& u:object_r:system_file:s0/g" | sed 's|\.|\\.|g' >> $target_contexts
    if [ $(echo $files | grep "bin$") ];then
      echo $files | sed "s#\./#/#g" | sed "s/^/&system/g" | sed "s/$/& 0 2000 0755/g" >> $target_fs
    else
      echo $files | sed "s#\./#/#g" | sed "s/^/&system/g" | sed "s/$/& 0 0 0755/g" >> $target_fs
    fi
  fi

  if [ -f $files ];then
    if [ $(echo $files | grep ".sh$") ];then
      echo $files | sed "s#\./#/#g" | sed "s/^/&\/system/g" | sed "s/$/& u:object_r:update_engine_exec:s0/g" | sed 's|\.|\\.|g' >> $target_contexts
      echo $files | sed "s#\./#/#g" | sed "s/^/&system/g" | sed "s/$/& 0 2000 0755/g" >> $target_fs
    elif [ $(echo $files | grep "/bin/") ];then
      echo $files | sed "s#\./#/#g" | sed "s/^/&\/system/g" | sed "s/$/& u:object_r:u:object_r:system_file:s0/g" | sed 's|\.|\\.|g' >> $target_contexts
      echo $files | sed "s#\./#/#g" | sed "s/^/&system/g" | sed "s/$/& 0 2000 0755/g" >> $target_fs    
    else
      echo $files | sed "s#\./#/#g" | sed "s/^/&\/system/g" | sed "s/$/& u:object_r:system_file:s0/g" | sed 's|\.|\\.|g' >> $target_contexts
      echo $files | sed "s#\./#/#g" | sed "s/^/&system/g" | sed "s/$/& 0 0 0644/g" >> $target_fs
    fi  
  fi
done

sed -i '1d' $target_contexts
sed -i '1d' $target_fs

if [ -f $LOCALDIR/remove_define.sh ];then
  $LOCALDIR/remove_define.sh
fi
