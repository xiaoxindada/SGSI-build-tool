#!/bin/bash

LOCALDIR=`cd "$( dirname $0 )" && pwd`
cd $LOCALDIR

systemdir="../../../out/system/system"
configdir="../../../out/config"
vendordir="../../../out/vendor"

# 清除该死的miui推广上下文导致的几乎所有机型bootloop或者直接启动到rec
sed -i '/miui.reverse.charge/d' $systemdir/system_ext/etc/selinux/system_ext_property_contexts
sed -i '/ro.cust.test/d' $systemdir/system_ext/etc/selinux/system_ext_property_contexts
sed -i '/miui.reverse.charge/d' $systemdir/product/etc/selinux/product_property_contexts
sed -i '/ro.cust.test/d' $systemdir/product/etc/selinux/product_property_contexts   

# 禁用MIUI无用的系统性能分析
rm -rf $systemdir/xbin/system_perf_init

# 禁用MIUI颜色反转
sed -i '/ro.vendor.df.effect.conflict/d' $systemdir/build.prop
sed -i '/persist.sys.df.extcolor.proc/d' $systemdir/build.prop

# 禁用MIUI部分display属性
sed -i '/persist.sys.wfd.virtual/d' $systemdir/build.prop
sed -i '/debug.sf.enable_hwc_vds/d' $systemdir/build.prop
sed -i '/sys.displayfeature_hidl/d' $systemdir/build.prop

# 禁用MIUI QCA检测
sed -i '/sys,qca/d' $systemdir/build.prop

# 禁用MIUI paper模式
sed -i '/sys.paper_mode_max_level\=/d' $systemdir/build.prop
sed -i '/sys.tianma/d' $systemdir/build.prop
sed -i '/sys.huaxing/d' $systemdir/build.prop
sed -i '/sys.shenchao/d' $systemdir/build.prop

# MIUI 分辨率自适应
sed -i 's/persist.miui.density_v2/#&/' $systemdir/build.prop
sed -i 's/persist.miui.density_v2/#&/' $systemdir/product/build.prop
sed -i 's/persist.miui.density_v2/#&/' $systemdir/system_ext/build.prop

# MIUI device_feature修补
device_features=$(find $systemdir -type d -name 'device_features')
vendor_device_features=$(find $vendordir -type d -name 'device_features')
xml_name=$(ls $vendor_device_features)
if [[ ! -e $device_features ]] && [[ -e $vendor_device_features ]];then
  cp -frp $vendor_device_features $systemdir/etc/
  echo "/system/system/etc/device_features u:object_r:system_file:s0" >> $configdir/system_file_contexts
  echo "/system/system/etc/device_features/$xml_name u:object_r:system_file:s0" >> $configdir/system_file_contexts
  echo "system/system/etc/device_features 0 0 0755" >> $configdir/system_fs_config
  echo "system/system/etc/device_features/$xml_name 0 0 0644" >> $configdir/system_fs_config
  sed -i '/^\s*$/d' $configdir/system_file_contexts
  sed -i '/^\s*$/d' $configdir/system_fs_config
fi

# xiaomi missi
missi() {
  cat $systemdir/build.prop | grep -qo "missi"
}
if missi ;then
  # add libs
  cp -frpn $LOCALDIR/add_libs/system/* $systemdir
  
  # missi机型修复
  echo "检测到原包为missi 启用机型参数修复" 
  brand=$(cat $vendordir/build.prop | grep 'ro.product.vendor.brand')
  device=$(cat $vendordir/build.prop | grep 'ro.product.vendor.device')
  manufacturer=$(cat $vendordir/build.prop | grep 'ro.product.vendor.manufacturer')
  model=$(cat $vendordir/build.prop | grep 'ro.product.vendor.model')
  mame=$(cat $vendordir/build.prop | grep 'ro.product.vendor.name')
  marketname=$(cat $vendordir/build.prop | grep 'ro.product.vendor.marketname')
  
  echo "当前原包机型参数为:"
  echo "$brand"
  echo "$device"
  echo "$manufacturer"
  echo "$model"
  echo "$mame"
  echo "$marketname"

  echo "正在修复"
  sed -i '/ro.product.system./d' $systemdir/build.prop
  echo "" >> $systemdir/build.prop
  echo "# 设备参数" >> $systemdir/build.prop
  echo "$brand" >> $systemdir/build.prop
  echo "$device" >> $systemdir/build.prop
  echo "$manufacturer" >> $systemdir/build.prop
  echo "$model" >> $systemdir/build.prop
  echo "$mame" >> $systemdir/build.prop
  echo "$marketname" >> $systemdir/build.prop
  sed -i 's/ro.product.vendor./ro.product.system./g' $systemdir/build.prop
  sed -i '/ro.product.property_source_order\=/d' $systemdir/build.prop
  echo "" >> $systemdir/build.prop
  echo "# 机型专有设备参数默认读取顺序" >> $systemdir/build.prop
  echo "ro.product.property_source_order=system,product,system_ext,vendor,odm" >> $systemdir/build.prop
  cat $LOCALDIR/add_rw-system.sh >> $systemdir/bin/rw-system.sh 
  # echo "因为xiaomi魔改的原因 以上操作只是完善set环境和调用参数， 完全修复机型识别清在此基础上手动修改/odm/build.prop里面的参数"
  echo "修复完成" 
fi
