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

# init.environ环境修补
if ! (cat $systemdir/../init.environ.rc | grep -qo "BOOTCLASSPATH") ;then
  cat $LOCALDIR/init.environ_BOOTCLASSPATH.patch >> $systemdir/../init.environ.rc
fi

if ! (cat $systemdir/../init.environ.rc | grep -qo "DEX2OATBOOTCLASSPATH") ;then
  cat $LOCALDIR/init.environ_DEX2OATBOOTCLASSPATH.patch >> $systemdir/../init.environ.rc
fi

if ! (cat $systemdir/../init.environ.rc | grep -qo "SYSTEMSERVERCLASSPATH") ;then
  cat $LOCALDIR/init.environ_SYSTEMSERVERCLASSPATH.patch >> $systemdir/../init.environ.rc
fi

sed -i '/^\s*$/d' $systemdir/../init.environ.rc
