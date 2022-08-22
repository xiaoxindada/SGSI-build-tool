#!/bin/bash

LOCALDIR=`cd "$( dirname $0 )" && pwd`
cd $LOCALDIR

systemdir="../out/system/system"
configdir="../out/config"
bin="../bin"

cp -frp ./oos/system/* $systemdir

# fs数据整合
cat ./oos/fs/fs >> $configdir/system_fs_config
cat ./oos/fs/contexts >> $configdir/system_file_contexts
cat ./oos/build >> $systemdir/build.prop