#!/bin/bash

#build修复
id="$(cat ../out/system/system/build.prop | grep 'ro.rom.version=' | sed 's/ro.rom.version=//g')"
model="$(cat ../out/vendor/build.prop |grep 'ro.product.vendor.model=' | sed 's/ro.product.vendor.model=//g')"
echo "当前系统版本号为:$id"
echo "当前机型为:$model"
echo "已将上述参数整合进build"
echo "
#设备参数
ro.product.model=$model
ro.build.display.id=$id
" >> ../out/system/system/build.prop

#cp -frp ./h2os/system/* ../out/system/system/
