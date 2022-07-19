#!/bin/bash

LOCALDIR=`cd "$( dirname ${BASH_SOURCE[0]} )" && pwd`
cd $LOCALDIR
source ./bin.sh 
source ./language_helper.sh

chmod -R 777 ./
rm -rf $WORKSPACE
rm -rf ./new_dat
rm -rf ./boot
rm -rf ./vendor_boot
rm -rf ./out
rm -rf ./super
rm -rf ./tmp/*
rm -rf ./SGSI
rm -rf ./images
rm -rf ./dtbo
rm -rf ./dtbs
rm -rf ./payload/out/*
rm -rf $COMPONENT/dynamic_fs
rm -rf $COMPONENT/add_dynamic_fs
rm -rf $COMPONENT/lib_fs
rm -rf $COMPONENT/new_fs
rm -rf $COMPONENT/config
rm -rf $COMPONENT/apex_fs
rm -rf $COMPONENT/lib_fs
rm -rf ./extract
true > ./1.sh
true > ./2.sh
true > ./3.sh
find ./ -type f -name '*.pyc' -delete
find ./ -type f -name '*.bak' -delete
find ./ -type f -name '*.ozip' -delete
find ./ -type f -name '*.bin' -delete
find ./ -type f -name '*.img' -delete
find ./ -type f -name 'dtb*' -delete
find ./ -maxdepth 1 -type f -name '*.txt' -delete
$bin/rm.sh
$COMPONENT/rm.sh
partition_list="system system_ext product vendor"
for partition in $partition_list ;do
  umount $partition 2>/dev/null
  rm -rf $partition
done

true > $COMPONENT/add_etc_vintf_patch/manifest_custom
echo "" >> $COMPONENT/add_etc_vintf_patch/manifest_custom
echo "<!-- oem hal -->" >> $COMPONENT/add_etc_vintf_patch/manifest_custom

true > $COMPONENT/add_build/oem_prop
echo "" >> $COMPONENT/add_build/oem_prop
echo "# oem common prop" >> $COMPONENT/add_build/oem_prop

echo "$WORKSPACECLEAND_STR"
