#!/bin/bash

LOCALDIR=`cd "$( dirname $0 )" && pwd`
cd $LOCALDIR

romdir="$LOCALDIR/color"
systemdir="$LOCALDIR/../out/system/system"
configdir="$LOCALDIR/../out/config"
my_product_dir="$systemdir/../my_product"

# 自动亮度关闭
cp -frp $romdir/system/etc/init/colorosbrightness.rc $systemdir/etc/init/

# 圆角、水滴等 去除
if [ -d $my_product_dir ];then
  xmldir="$my_product_dir/etc/permissions"
  xmls=" \
    oplus.product.display_features.xml \
    oplus.product.display_features_deprecated.xml \
    com.oppo.features_display.xml \
    oplus.product.feature_multimedia_unique.xml \
  "
  for xml_name in $xmls ;do
    if [ -f $xmldir/$xml_name ];then
      sed -i '/roundcorner/d' $xmldir/$xml_name
    fi
  done
fi

# fs数据整合
cat $romdir/fs/fs >> $configdir/system_fs_config
cat $romdir/fs/contexts >> $configdir/system_file_contexts
