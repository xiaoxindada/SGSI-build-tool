#!/bin/bash
 
LOCALDIR=`cd "$( dirname $0 )" && pwd`
cd $LOCALDIR

configdir="$LOCALDIR/../out/config"
target_fs="$configdir/system_fs_config"
target_contexts="$configdir/system_file_contexts"

echo "正在添加patch文件的fs"

for get_fs in $(find $LOCALDIR -type f | grep "get_fs.sh$");do
  $get_fs
done

for repack_file_contexts in $(find $LOCALDIR -type f | grep "add_repack_contexts$");do
  cat $repack_file_contexts >> $target_contexts
done

for repack_file_fs in $(find $LOCALDIR -type f | grep "add_repack_fs$");do
  cat $repack_file_fs >> $target_fs
done

if [ -d $LOCALDIR/add_fs ];then
  for i in $(ls $LOCALDIR/add_fs | grep "contexts$");do
      if [ -f $LOCALDIR/add_fs/$i ];then
        cat $LOCALDIR/add_fs/$i >> $target_contexts
      fi
  done

  for i in $(ls $LOCALDIR/add_fs | grep "fs$");do
      if [ -f $LOCALDIR/add_fs/$i ];then
        cat $LOCALDIR/add_fs/$i >> $target_fs
      fi
  done
fi
