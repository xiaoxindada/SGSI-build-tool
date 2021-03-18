#!/bin/bash

LOCALDIR=`cd "$( dirname $0 )" && pwd`
cd $LOCALDIR

tar -xf ./ABboot.tar -C ../../out/system/

contexts="../../out/config/system_file_contexts"
fs="../../out/config/system_fs_config"

sed -i '/\/system\/acct /d' $contexts
#sed -i '/\/system\/apex /d' $contexts
#sed -i '/\/system\/bin /d' $contexts
sed -i '/\/system\/bugreports /d' $contexts
sed -i '/\/system\/cache /d' $contexts
sed -i '/\/system\/config /d' $contexts
sed -i '/\/system\/d /d' $contexts
sed -i '/\/system\/data /d' $contexts
sed -i '/\/system\/data_mirror /d' $contexts
sed -i '/\/system\/default.prop /d' $contexts
sed -i '/\/system\/dev /d' $contexts
#sed -i '/\/system\/etc /d' $contexts
sed -i '/\/system\/linkerconfig /d' $contexts
#sed -i '/\/system\/init /d' $contexts
sed -i '/\/system\/metadata /d' $contexts
sed -i '/\/system\/mnt /d' $contexts
sed -i '/\/system\/odm /d' $contexts
sed -i '/\/system\/odm\/app /d' $contexts
sed -i '/\/system\/odm\/bin /d' $contexts
sed -i '/\/system\/odm\/etc /d' $contexts
sed -i '/\/system\/odm\/firmware /d' $contexts
sed -i '/\/system\/odm\/framework /d' $contexts
sed -i '/\/system\/odm\/lib /d' $contexts
sed -i '/\/system\/odm\/lib64 /d' $contexts
sed -i '/\/system\/odm\/overlay /d' $contexts
sed -i '/\/system\/odm\/priv-app /d' $contexts
sed -i '/\/system\/odm\/usr /d' $contexts
sed -i '/\/system\/oem /d' $contexts
sed -i '/\/system\/persist /d' $contexts
sed -i '/\/system\/proc /d' $contexts
#sed -i '/\/system\/sdcard /d' $contexts
sed -i '/\/system\/storage /d' $contexts
sed -i '/\/system\/sys /d' $contexts
sed -i '/\/system\/product /d' $contexts
sed -i '/\/system\/system_ext /d' $contexts
sed -i '/\/system\/vendor /d' $contexts

sed -i '/system\/acct /d' $fs
#sed -i '/system\/apex /d' $fs
#sed -i '/system\/bin /d' $fs
sed -i '/system\/bugreports /d' $fs
sed -i '/system\/cache /d' $fs
sed -i '/system\/config /d' $fs
sed -i '/system\/d /d' $fs
sed -i '/system\/data /d' $fs
sed -i '/system\/data_mirror /d' $fs
sed -i '/system\/default.prop /d' $fs
sed -i '/system\/dev /d' $fs
#sed -i '/system\/etc /d' $fs
sed -i '/system\/linkerconfig /d' $fs
#sed -i '/system\/init /d' $fs
sed -i '/system\/metadata /d' $fs
sed -i '/system\/mnt /d' $fs
sed -i '/system\/odm /d' $fs
sed -i '/system\/odm\/app /d' $fs
sed -i '/system\/odm\/bin /d' $fs
sed -i '/system\/odm\/etc /d' $fs
sed -i '/system\/odm\/firmware /d' $fs
sed -i '/system\/odm\/framework /d' $fs
sed -i '/system\/odm\/lib /d' $fs
sed -i '/system\/odm\/lib64 /d' $fs
sed -i '/system\/odm\/overlay /d' $fs
sed -i '/system\/odm\/priv-app /d' $fs
sed -i '/system\/odm\/usr /d' $fs
sed -i '/system\/oem /d' $fs
sed -i '/system\/persist /d' $fs
sed -i '/system\/proc /d' $fs
#sed -i '/system\/sdcard /d' $fs
sed -i '/system\/storage /d' $fs
sed -i '/system\/sys /d' $fs
sed -i '/system\/product /d' $fs
sed -i '/system\/system_ext /d' $fs
sed -i '/system\/vendor /d' $fs

cat ../ab_boot_fs/contexts >> $contexts
cat ../ab_boot_fs/fs >> $fs
