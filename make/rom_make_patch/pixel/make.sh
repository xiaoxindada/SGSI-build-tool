#!/bin/bash

LOCALDIR=`cd "$( dirname $0 )" && pwd`
cd $LOCALDIR

systemdir="$LOCALDIR/../../../out/system/system"
configdir="$LOCALDIR/../../../out/config"

# 为pixel启用强制向导跳过
echo "" >> $systemdir/build.prop
echo "#原生向导跳过" >> $systemdir/build.prop
echo "ro.setupwizard.mode=DISABLED" >> $systemdir/build.prop

echo "" >> $systemdir/product/etc/build.prop
echo "#原生向导跳过" >> $systemdir/product/etc/build.prop
echo "ro.setupwizard.mode=DISABLED" >> $systemdir/product/etc/build.prop

echo "" >> $systemdir/system_ext/etc/build.prop
echo "#原生向导跳过" >> $systemdir/system_ext/etc/build.prop
echo "ro.setupwizard.mode=DISABLED" >> $systemdir/system_ext/etc/build.prop
