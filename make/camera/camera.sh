#!/bin/bash

LOCALDIR=`cd "$( dirname $0 )" && pwd`
cd $LOCALDIR

systemdir="../../out/system/system"

if [ -d $systemdir/app/ ];then
  find $systemdir/app/ -name "*" | grep -i "camera" | xargs rm -rf
fi

if [ -d $systemdir/priv-app/ ];then
  find $systemdir/priv-app/ -name "*" | grep -i "camera" | xargs rm -rf
fi

if [ -d $systemdir/system_ext/app/ ];then
  find $systemdir/system_ext/app/ -name "*" | grep -i "camera" | xargs rm -rf
fi

if [ -d $systemdir/system-ext/priv-app/ ];then
  find $systemdir/system_ext/priv-app/ -name "*" | grep -i "camera" | xargs rm -rf
fi

if [ -d $systemdir/product/app/ ];then
  find $systemdir/product/app/ -name "*" | grep -i "camera" | xargs rm -rf
fi

if [ -d $systemdir/product/priv-app/ ];then
  find $systemdir/product/priv-app/ -name "*" | grep -i "camera" | xargs rm -rf
fi

cp -frp ./Camera $systemdir/app/

sed -i '/\/system\/system\/app\/Camera/d' ../../out/config/system_file_contexts
sed -i '/system\/system\/app\/Camera/d' ../../out/config/system_fs_config

cat ../add_fs/camera_fs >> ../../out/config/system_fs_config
cat ../add_fs/camera_contexts >> ../../out/config/system_file_contexts
