#!/bin/bash

LOCALDIR=`cd "$( dirname $0 )" && pwd`
cd $LOCALDIR

systemdir="../out/system/system"
configdir="../out/config"
bin="../bin"

cp -frp ./myos/system/* $systemdir

# fs数据整合
cat ./myos/fs/fs >> $configdir/system_fs_config
cat ./myos/fs/contexts >> $configdir/system_file_contexts
cat ./myos/build >> $systemdir/build.prop