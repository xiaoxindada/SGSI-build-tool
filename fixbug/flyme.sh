#!/bin/bash

LOCALDIR=`cd "$( dirname $0 )" && pwd`
cd $LOCALDIR

systemdir="../out/system/system"
configdir="../out/config"
bin="../bin"
signapk_tools_dir="$bin/tools/signapk"

cp -frp ./flyme/system/* $systemdir

# fs数据整合
cat ./flyme/fs/fs >> $configdir/system_fs_config
cat ./flyme/fs/contexts >> $configdir/system_file_contexts
