#!/bin/bash
 
LOCALDIR=`cd "$( dirname ${BASH_SOURCE[0]} )" && pwd`
cd $LOCALDIR

target_fs="$LOCALDIR/add_repack_fs"
target_contexts="$LOCALDIR/add_repack_contexts"

rm -rf $target_fs
rm -rf $target_contexts

for files in $(find ./system/ -name "*");do
  if [ -f $files ];then
    echo $files | sed "s#\./#/#g" | sed "s/^/&\/system/g" | sed "s/$/& u:object_r:system_lib_file:s0/g" | sed 's|\.|\\.|g' >> $target_contexts
    echo $files | sed "s#\./#/#g" | sed "s/^/&system/g" | sed "s/$/& 0 0 0644/g" >> $target_fs
  fi
  if [ -L $files ];then
    echo $files | sed "s#\./#/#g" | sed "s/^/&\/system/g" | sed "s/$/& u:object_r:system_lib_file:s0/g" | sed 's|\.|\\.|g' >> $target_contexts
    echo $files | sed "s#\./#/#g" | sed "s/^/&system/g" | sed "s/$/& 0 0 0644/g" >> $target_fs
  fi  
done
