#!/bin/bash
 
LOCALDIR=`cd "$( dirname $0 )" && pwd`
cd $LOCALDIR

systemdir=" ../out/system/system"

# pixel
pixel() {
  cat $systemdir/build.prop | grep -qo "Pixel"  \
  || cat $systemdir/product/build.prop | grep -qo "Pixel" \
  || cat $systemdir/system_ext/build.prop | grep -qo "Pixel"
 }
if pixel ;then
  echo "检测当前为pixel原生系统"
  #echo "正在完善特性"
  #./add_build.sh
  #./add_etc_vintf_patch/pixel/add_vintf.sh
  # rom修补处理
  ./rom_make_patch/pixel/make.sh
  echo "正在精简推广"
  ../apps_clean/pixel.sh "$systemdir"
fi
 
# 一加
oneplus=$(find ../out/system/ -type d -name 'reserve')
if [ ! $oneplus = "" ] ;then
  echo "检测当前为一加系统"
  echo "正在完善特性"
  #./add_build.sh
  ./add_etc_vintf_patch/h2os/add_vintf.sh
  echo "正在精简推广"
  ../apps_clean/h2os.sh "$systemdir"    
  # rom修补处理
  ./rom_make_patch/h2os/make.sh
fi 
 
 # flyme
flyme() {
  cat $systemdir/build.prop | grep -qo 'flyme'
 }
if flyme ;then
  echo "检测当前为Flyme系统"
  echo "正在完善特性"
  ./add_build.sh
  ./add_etc_vintf_patch/flyme/add_vintf.sh
   echo "正在精简推广"
   ../apps_clean/flyme.sh "$systemdir"  
fi
 
# miui
miui=$(find ../out/system/ -type d -name 'miui_feature' )   
if [ $miui ];then
  echo "检测当前为miui系统"
  echo "正在完善特性"
  ./add_build.sh
  ./add_etc_vintf_patch/miui/add_vintf.sh
  echo "正在精简推广"
  ../apps_clean/miui.sh "$systemdir"
  # rom修补处理
  ./rom_make_patch/miui/make.sh
fi
 
# joy
joy() {
  cat ../out/vendor/build.prop | grep -qo 'JoyUI'
} 
if joy ;then
  echo "检测到当前为Joy系统"
  cp -frp $(find ../out/vendor -type f -name 'init.blackshark.rc') $systemdir/etc/init/
  cp -frp $(find ../out/vendor -type f -name 'init.blackshark.common.rc') $systemdir/etc/init/
  echo "/system/system/etc/init/init\.blackshark\.common\.rc u:object_r:system_file:s0" >> ../out/config/system_file_contexts
  echo "/system/system/etc/init/init\.blackshark\.rc u:object_r:system_file:s0" >> ../out/config/system_file_contexts   
  sed -i '/^\s*$/d' ../out/config/system_file_contexts
  echo "system/system/etc/init/init.blackshark.common.rc 0 0 0644" >> ../out/config/system_fs_config
  echo "system/system/etc/init/init.blackshark.rc 0 0 0644" >> ../out/config/system_fs_config
  sed -i '/^\s*$/d' ../out/config/system_fs_config
fi

# nubia
nubia() {
  cat $systemdir/build.prop | grep -qo 'nubia'
}
if nubia ;then
  echo "检测到当前为nubia系统"
  echo "正在精简推广"
  ../apps_clean/nubia.sh "$systemdir"
fi  

# vivo
if [ -d $systemdir/build-in-app ];then
  echo "检测到当前为vivo系统"
  echo "正在完善特性"
  ./add_build.sh
  ./add_etc_vintf_patch/vivo/add_vintf.sh
   echo "正在精简推广"
  ../apps_clean/vivo.sh "$systemdir"    
  # rom修补处理
  ./rom_make_patch/vivo/make.sh  
fi

# oppo
oppo=$(find $systemdir/../ -type d -name "my_product") 

if [ $oppo ];then
  echo "检测到当前为oppo系统"
  echo "正在完善特性"
  ./add_build.sh
  ./add_etc_vintf_patch/color/add_vintf.sh   
  # rom修补处理
  echo "正在进行专有处理"
  ./rom_make_patch/color/make.sh
fi
