#!/bin/bash

LOCALDIR=`cd "$( dirname $0 )" && pwd`
cd $LOCALDIR

systemdir="../../../out/system/system"
configdir="../../../out/config"
vendordir="../../../out/vendor"

# 删除多余文件
rm -rf $systemdir/data
rm -rf $systemdir/../init.vivo.soc.rc

# 禁用cpu平台验证
sed -i '/ro.vivo.product.solution/d' $systemdir/build.prop
sed -i '/ro.vivo.product.platform/d' $systemdir/build.prop

# 分辨率等
sed -i '/ro.vivo.lcm.xhd/d' $systemdir/build.prop
