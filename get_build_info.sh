#!/bin/bash

LOCALDIR=`cd "$( dirname $0 )" && pwd`
cd $LOCALDIR

systemdir="$1"
image_file="$2"

device_manufacturer=$(cat $systemdir/build.prop | grep "ro.product.system.manufacture" | head -n 1 | cut -d "=" -f 2)
android_version=$(cat $systemdir/build.prop | grep "ro.build.version.release" | head -n 1 | cut -d "=" -f 2)
android_code_name=$(cat $systemdir/build.prop | grep "ro.build.version.codename" | head -n 1 | cut -d "=" -f 2)
device_product=$(cat $systemdir/build.prop | grep "ro.build.product=" | head -n 1 | cut -d "=" -f 2)
android_sdk=$(cat $systemdir/build.prop | grep "ro.build.version.sdk" | head -n 1 | cut -d "=" -f 2)
andriod_spl=$(cat $systemdir/build.prop | grep "ro.build.version.security_patch" | head -n 1 | cut -d "=" -f 2)
device_model=$(cat $systemdir/build.prop | grep "ro.product.system.model" | head -n 1 | cut -d "=" -f 2)
description_info=$(cat $systemdir/build.prop | grep "ro.build.description" | head -n 1 | cut -d "=" -f 2)
android_fingerprint=$(cat $systemdir/build.prop | grep "ro.system.build.fingerprint" | head -n 1 | cut -d "=" -f 2)
android_image_name=$(echo ${image_file##*/})
android_image_size=$(echo `(du -sm $image_file | awk '{print $1}' | sed 's/$/&MB/')`)
build_date=$(date +%Y-%m-%d-%H:%M)

echo "
厂商: $device_manufacturer
安卓版本: $android_version
安卓code名称: $android_code_name
机型代号： $device_product
安卓sdk版本: $android_sdk
安卓spl日期: $andriod_spl
设备型号： $device_model
description: $description_info
build指纹信息： $android_fingerprint
$android_image_name大小: $android_image_size
构建日期: $build_date
"
