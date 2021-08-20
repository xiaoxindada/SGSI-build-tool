#!/bin/bash

LOCALDIR=`cd "$( dirname ${BASH_SOURCE[0]} )" && pwd`
cd $LOCALDIR

clean_dirs="add_libs system_patch"
for clean_dir in $clean_dirs ;do
  if [ -d $LOCALDIR/$clean_dir ];then
    rm -rf $LOCALDIR/$clean_dir/add_repack_contexts $LOCALDIR/$clean_dir/add_repack_fs
  fi
done

