#!/bin/bash

LOCALDIR=`cd "$( dirname $0 )" && pwd`
cd $LOCALDIR

bin="$LOCALDIR/../../../tool_bin"
systemdir="$LOCALDIR/../../../out/system/system"
configdir="$LOCALDIR/../../../out/config"
toolsdir="$LOCALDIR/../../.."
tmpdir="$LOCALDIR/tmp"
outdir="$tmpdir/out"
odmdir="$outdir/odm"
odm_configdir="$outdir/config"

rm -rf $tmpdir
mkdir -p $tmpdir
mkdir -p $outdir

# 为oneplus禁用向导的上下文 以保证在部分机型上发生的向导fc
sed -i '/ro.setupwizard.mode/d' $systemdir/etc/selinux/plat_property_contexts 
sed -i '/ro.setupwizard.mode/d' $systemdir/build.prop 
sed -i '/ro.setupwizard.mode/d' $systemdir/product/build.prop
sed -i '/setupwizard.feature.baseline_setupwizard_enabled/d' $systemdir/build.prop
sed -i '/setupwizard.feature.baseline_setupwizard_enabled/d' $systemdir/product/build.prop

# 合并odm分区
echo "合并odm分区中"
cp $toolsdir/odm.img $tmpdir/
python3 $bin/imgextractor.py $tmpdir/odm.img $outdir > /dev/null 2>&1
rm -rf $odmdir/lost+found
rm -rf $odmdir/etc/selinux

rm -rf $systemdir/odm
cp -frp $odmdir $systemdir
sed -i '1d' $odm_configdir/odm_file_contexts
sed -i '2d' $odm_configdir/odm_file_contexts
sed -i '3d' $odm_configdir/odm_file_contexts

sed -i '1d' $odm_configdir/odm_fs_config
sed -i '2d' $odm_configdir/odm_fs_config

sed -i '/\?/d' $odm_configdir/odm_file_contexts
sed -i "s#/odm/#/system/system/odm/#g" $odm_configdir/odm_file_contexts
sed -i "s#odm/#system/system/odm/#g" $odm_configdir/odm_fs_config

echo "/system/system/odm u:object_r:vendor_file:s0" >> $odm_configdir/odm_file_contexts
echo "system/system/odm 0 0 0755" >> $odm_configdir/odm_fs_config

cat $odm_configdir/odm_file_contexts >> $configdir/system_file_contexts
cat $odm_configdir/odm_fs_config >> $configdir/system_fs_config

echo "合并完成"

echo "进行其他修补"
# 给rw-system.sh添加附加属性
cat $LOCALDIR/add_rw-system.sh >> $systemdir/bin/rw-system.sh

# system patch 
cp -frp $LOCALDIR/system/* $systemdir
cat $LOCALDIR/contexts >> $configdir/system_file_contexts
cat $LOCALDIR/fs >> $configdir/system_fs_config

rm -rf $tmpdir
