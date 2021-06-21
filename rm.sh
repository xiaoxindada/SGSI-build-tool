#!/bin/sh

LOCALDIR=`cd "$( dirname $0 )" && pwd`
cd $LOCALDIR

chmod -R 777 ./
rm -rf ./new_dat
rm -rf ./boot
rm -rf ./out
rm -rf ./super
rm -rf ./tmp/*
rm -rf ./SGSI
rm -rf ./images
rm -rf ./dtbo
rm -rf ./dtbs
rm -rf ./payload/out/*
rm -rf ./make/add_dynamic_fs
rm -rf ./make/lib_fs
rm -rf ./make/new_fs
rm -rf ./make/config
rm -rf ./make/apex_fs
rm -rf ./make/lib_fs
rm -rf ./extract
true > ./1.sh
true > ./2.sh
true > ./3.sh
find ./ -type f -name '*.pyc' -delete
find ./ -type f -name '*.bak' -delete
find ./ -type f -name '*.ozip' -delete
find ./ -type f -name '*.bin' -delete
find ./ -type f -name '*.img' -delete
find ./ -maxdepth 1 -type f -name '*.txt' -delete
./bin/oat2dex/rm.sh
./fixbug/light_fix/rm.sh
./fixbug/wifi_fix/rm.sh
./fixbug/rm.sh

true > ./make/add_etc_vintf_patch/manifest_custom
echo "" >> ./make/add_etc_vintf_patch/manifest_custom
echo "<!-- oem自定义接口 -->" >> ./make/add_etc_vintf_patch/manifest_custom

true > ./make/add_build/add_oem_build
echo "" >> ./make/add_build/add_oem_build
echo "# oem厂商自定义属性" >> ./make/add_build/add_oem_build

echo "工具环境清理完成"
