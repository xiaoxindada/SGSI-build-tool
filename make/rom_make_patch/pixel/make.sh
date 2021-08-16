#!/bin/bash

LOCALDIR=`cd "$( dirname $0 )" && pwd`
cd $LOCALDIR
WORKSPACE=$LOCALDIR/../../../workspace
IMAGESDIR=$WORKSPACE/images
TARGETDIR=$WORKSPACE/out

systemdir="$TARGETDIR/system/system"
configdir="$TARGETDIR/config"

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

init_environ_patch() {
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
}
if [ $(cat $systemdir/build.prop | grep "ro.build.version.codename" | head -n 1 | cut -d "=" -f 2) = "S" ];then
  init_environ_patch
fi

# 12暂时启用apex更新
enable_apex() {
  sed -i '/ro.apex.updatable/d' $systemdir/build.prop
  sed -i '/ro.apex.updatable/d' $systemdir/product/etc/build.prop
  sed -i '/ro.apex.updatable/d' $systemdir/system_ext/etc/build.prop
  echo "" >> $systemdir/product/etc/build.prop
  echo "ro.apex.updatable=true" >> $systemdir/product/etc/build.prop
  for apex_dir in $(ls $systemdir/apex);do
    if [ -d $systemdir/apex/$apex_dir ];then
      rm -rf $systemdir/apex/$apex_dir
    fi
  done
}
if [ $(cat $systemdir/build.prop | grep "ro.build.version.sdk" | head -n 1 | cut -d "=" -f 2) = "31" ];then
  enable_apex
  cp -frp $LOCALDIR/system/* $systemdir/
fi
