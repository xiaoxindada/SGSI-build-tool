#!/bin/bash

LOCALDIR=`cd "$( dirname $0 )" && pwd`
cd $LOCALDIR

systemdir="../../../out/system/system"
configdir="../../../out/config"

# 为pixel启用强制向导跳过
echo "" >> $systemdir/build.prop
echo "#原生向导跳过" >> $systemdir/build.prop
echo "ro.setupwizard.mode=DISABLED" >> $systemdir/build.prop

echo "" >> $systemdir/product/build.prop
echo "#原生向导跳过" >> $systemdir/product/build.prop
echo "ro.setupwizard.mode=DISABLED" >> $systemdir/product/build.prop

echo "" >> $systemdir/system_ext/build.prop
echo "#原生向导跳过" >> $systemdir/system_ext/build.prop
echo "ro.setupwizard.mode=DISABLED" >> $systemdir/system_ext/build.prop

# 清空pixel无用的上下文导致的启动至rec
if [ -e $systemdir/product/etc/selinux/mapping ];then
  true > $systemdir/product/etc/selinux/product_property_contexts
fi
