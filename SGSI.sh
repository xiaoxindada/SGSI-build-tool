#!/bin/bash

# Copyright (C) 2020 Xiaoxindada <2245062854@qq.com>

LOCALDIR=`cd "$( dirname $0 )" && pwd`
cd $LOCALDIR
source ./bin.sh

systemdir="$LOCALDIR/out/system/system"
configdir="$LOCALDIR/out/config"

Usage() {
cat <<EOT
Usage:
$0 AB|ab or $0 A|a
EOT
}

case $1 in 
  "AB"|"ab"|"A"|"a")
    echo "" > /dev/null 2>&1
    ;;
  *)
    Usage
    exit
    ;;
esac

rm -rf ./out
rm -rf ./SGSI
mkdir ./out

if [ -e ./vendor.img ];then
  echo "解压vendor.img中..."
  python3 $bin/imgextractor.py ./vendor.img ./out
  if [ $? = "1" ];then
    echo "vendor.img解压失败！"
    exit
  fi
fi
echo "解压system.img中..."
python3 $bin/imgextractor.py ./system.img ./out
if [ $? = "1" ];then
  echo "system.img解压失败！"
  exit
fi

model="$(cat $systemdir/build.prop | grep 'model')"
echo "当前原包机型为:"
echo "$model"

function normal() {
  # 为所有rom修改ramdisk层面的system
  echo "正在修改system外层"
  cd ./make/ab_boot
  ./ab_boot.sh
  cd $LOCALDIR
  echo "修改完成"

  # apex_vndk 修改
  cd ./make/apex_vndk_start
  ./make.sh
  cd $LOCALDIR 
 
  # apex_fs数据整合
  cd ./make/apex_flat
  ./add_apex_fs.sh
  cd $LOCALDIR

  echo "正在进行其他处理"

  # 重置make目录
  true > ./make/add_etc_vintf_patch/manifest_custom
  echo "" >> ./make/add_etc_vintf_patch/manifest_custom
  echo "<!-- oem自定义接口 -->" >> ./make/add_etc_vintf_patch/manifest_custom

  true > ./make/add_build/add_oem_build
  echo "" >> ./make/add_build/add_oem_build
  echo "# oem厂商自定义属性" >> ./make/add_build/add_oem_build
 
  # 为所有rom添加抓logcat的文件
  cp -frp ./make/add_logcat/system/* $systemdir/
  cat ./make/add_logcat_fs/contexts >> $configdir/system_file_contexts
  cat ./make/add_logcat_fs/fs >> $configdir/system_fs_config

  # 为所有rom做usb通用化
  cp -frp ./make/aosp_usb/* $systemdir/etc/init/hw/

  # 为所有rom做selinux通用化处理
  sed -i "/typetransition location_app/d" $systemdir/etc/selinux/plat_sepolicy.cil
  sed -i '/u:object_r:vendor_default_prop:s0/d' $systemdir/etc/selinux/plat_property_contexts
  sed -i '/software.version/d'  $systemdir/etc/selinux/plat_property_contexts
  sed -i 's/sys.usb.config          u:object_r:system_radio_prop:s0//g' $systemdir/etc/selinux/plat_property_contexts
  sed -i 's/ro.build.fingerprint    u:object_r:fingerprint_prop:s0//g' $systemdir/etc/selinux/plat_property_contexts

  if [ -e $systemdir/product/etc/selinux/mapping ];then
    find $systemdir/product/etc/selinux/mapping/ -type f -empty | xargs rm -rf
    sed -i '/software.version/d'  $systemdir/product/etc/selinux/product_property_contexts
    sed -i '/vendor/d' $systemdir/product/etc/selinux/product_property_contexts
    sed -i '/secureboot/d' $systemdir/product/etc/selinux/product_property_contexts
    sed -i '/persist/d' $systemdir/product/etc/selinux/product_property_contexts
    sed -i '/oem/d' $systemdir/product/etc/selinux/product_property_contexts
  fi
 
  if [ -e $systemdir/system_ext/etc/selinux/mapping ];then
    find $systemdir/system_ext/etc/selinux/mapping/ -type f -empty | xargs rm -rf
    sed -i '/software.version/d'  $systemdir/system_ext/etc/selinux/system_ext_property_contexts
    sed -i '/vendor/d' $systemdir/system_ext/etc/selinux/system_ext_property_contexts
    sed -i '/secureboot/d' $systemdir/system_ext/etc/selinux/system_ext_property_contexts
    sed -i '/persist/d' $systemdir/system_ext/etc/selinux/system_ext_property_contexts
    sed -i '/oem/d' $systemdir/system_ext/etc/selinux/system_ext_property_contexts
  fi
 
  build_modify() {
  # 为所有qssi原包修复机型数据
    qssi() {
      cat $systemdir/build.prop | grep -qo 'qssi'
    }
    if qssi ;then
      echo "检测到原包为qssi 启用机型参数修复" 
      brand=$(cat ./out/vendor/build.prop | grep 'ro.product.vendor.brand')
      device=$(cat ./out/vendor/build.prop | grep 'ro.product.vendor.device')
      manufacturer=$(cat ./out/vendor/build.prop | grep 'ro.product.vendor.manufacturer')
      model=$(cat ./out/vendor/build.prop | grep 'ro.product.vendor.model')
      mame=$(cat ./out/vendor/build.prop | grep 'ro.product.vendor.name')
  
      echo "当前原包机型参数为:"
      echo "$brand"
      echo "$device"
      echo "$manufacturer"
      echo "$model"
      echo "$mame"

      echo "正在修复"
      sed -i '/ro.product.system./d' $systemdir/build.prop
      echo "" >> $systemdir/build.prop
      echo "# 设备参数" >> $systemdir/build.prop
      echo "$brand" >> $systemdir/build.prop
      echo "$device" >> $systemdir/build.prop
      echo "$manufacturer" >> $systemdir/build.prop
      echo "$model" >> $systemdir/build.prop
      echo "$mame" >> $systemdir/build.prop
      sed -i 's/ro.product.vendor./ro.product.system./g' $systemdir/build.prop
      echo "修复完成"
    fi
 
    # 为所有rom改用分辨率自适应
    sed -i 's/ro.sf.lcd/#&/' $systemdir/build.prop
    sed -i 's/ro.sf.lcd/#&/' $systemdir/product/build.prop
    sed -i 's/ro.sf.lcd/#&/' $systemdir/system_ext/build.prop
   
    # 为所有rom启用CDM电话的系统属性
    sed -i '/telephony.lteOnCdmaDevice/d' $systemdir/build.prop
    sed -i '/telephony.lteOnCdmaDevice/d' $systemdir/product/build.prop
    sed -i '/telephony.lteOnCdmaDevice/d' $systemdir/system_ext/build.prop
    echo "" >> $systemdir/build.prop   
    echo "# System prop to turn on CdmaLTEPhone always" >> $systemdir/build.prop
    echo "telephony.lteOnCdmaDevice=1" >> $systemdir/build.prop
    echo "" >> $systemdir/product/build.prop
    echo "# System prop to turn on CdmaLTEPhone always" >> $systemdir/product/build.prop
    echo "telephony.lteOnCdmaDevice=1" >> $systemdir/product/build.prop
    echo "" >> $systemdir/system_ext/build.prop
    echo "# System prop to turn on CdmaLTEPhone always" >> $systemdir/system_ext/build.prop
    echo "telephony.lteOnCdmaDevice=1" >> $systemdir/system_ext/build.prop       
  
    # 为所有rom清理一些无用属性
    sed -i '/vendor.display/d' $systemdir/build.prop
    sed -i '/vendor.perf/d' $systemdir/build.prop
    sed -i '/debug.sf/d' $systemdir/build.prop
    sed -i '/persist.sar.mode/d' $systemdir/build.prop
    sed -i '/opengles.version/d' $systemdir/build.prop

    # 为所有rom禁用product vndk version
    sed -i '/product.vndk.version/d' $systemdir/product/build.prop

    # 为所有rom禁用caf media.setting
    sed -i '/media.settings.xml/d' $systemdir/build.prop

    # 为所有rom添加必要的通用属性
    sed -i '/system_root_image/d' $systemdir/build.prop
    sed -i '/ro.control_privapp_permissions/d' $systemdir/build.prop
    sed -i '/ro.control_privapp_permissions/d' $systemdir/product/build.prop
    sed -i '/ro.control_privapp_permissions/d' $systemdir/system_ext/build.prop  
    cat ./make/add_build/add_build >> $systemdir/build.prop
    cat ./make/add_build/add_product_build >> $systemdir/product/build.prop
    cat ./make/add_build/add_system_ext_build >> $systemdir/system_ext/build.prop

    # 为所有rom启用虚拟建
    mainkeys() {
      grep -q 'qemu.hw.mainkeys=' $systemdir/build.prop
    }  
    if mainkeys ;then
      sed -i 's/qemu.hw.mainkeys\=1/qemu.hw.mainkeys\=0/g' $systemdir/build.prop
    else
      echo "" >> $systemdir/build.prop
      echo "# 启用虚拟键" >> $systemdir/build.prop
      echo "qemu.hw.mainkeys=0" >> $systemdir/build.prop
    fi

    # 为所有qssi原包修改默认设备参数读取
    source_order() {
      grep -q 'ro.product.property_source_order=' $systemdir/build.prop
    }
    if source_order ;then
      sed -i '/ro.product.property\_source\_order\=/d' $systemdir/build.prop  
      echo "" >> $systemdir/build.prop
      echo "# 机型专有设备参数默认读取顺序" >> $systemdir/build.prop
      echo "ro.product.property_source_order=system,product,system_ext,vendor,odm" >> $systemdir/build.prop
    fi
  }
  build_modify

  # 为所有rom还原fstab.postinstall
  find  ./out/system/ -type f -name "fstab.postinstall" | xargs rm -rf
  cp -frp ./make/fstab/system/* $systemdir
  sed -i '/fstab\\.postinstall/d' $configdir/system_file_contexts
  sed -i '/fstab.postinstall/d' $configdir/system_fs_config
  cat ./make/add_fs/fstab_contexts >> $configdir/system_file_contexts
  cat ./make/add_fs/fstab_fs >> $configdir/system_fs_config 

  # 添加缺少的libs
  cp -frpn ./make/add_libs/system/* $systemdir
 
  # 为default启用debug调试
  sed -i 's/persist.sys.usb.config=none/persist.sys.usb.config=adb/g' $systemdir/etc/prop.default
  sed -i 's/ro.debuggable=0/ro.debuggable=1/g' $systemdir/etc/prop.default
  sed -i 's/ro.adb.secure=1/ro.adb.secure=0/g' $systemdir/etc/prop.default
  echo "ro.force.debuggable=1" >> $systemdir/etc/prop.default
 
  # 为default修补oem的SurfaceFlinger属性
  if [ -e ./out/vendor/default.prop ];then
    rm -rf ./default.txt
    cat ./out/vendor/default.prop | grep 'surface_flinger' > ./default.txt
  fi
  default="$(find $systemdir -type f -name 'prop.default')"
  if [ ! $default = "" ];then
    if [ -e ./default.txt ];then
      surface_flinger() {
        default="$(find $systemdir -type f -name 'prop.default')"
        cat $default | grep -q 'surface_flinger'
      }
      if surface_flinger ;then
        rm -rf ./default.txt
      else
        echo "" >> $default
        cat ./default.txt >> $default
        rm -rf ./default.txt
      fi
    fi
  fi

  # 为所有rom删除qti_permissions
  find $systemdir -type f -name "qti_permissions.xml" | xargs rm -rf

  # 为所有rom删除firmware
  find $systemdir -type d -name "firmware" | xargs rm -rf

  # 为所有rom删除avb
  find $systemdir -type d -name "avb" | xargs rm -rf
  
  # 为所有rom删除com.qualcomm.location
  find $systemdir -type d -name "com.qualcomm.location" | xargs rm -rf

  # 为所有rom删除多余文件
  rm -rf ./out/system/verity_key
  rm -rf ./out/system/init.recovery*
  rm -rf $systemdir/recovery-from-boot.*

  # 为所有rom patch system
  cp -frp ./make/system_patch/system/* $systemdir/

  # 为所有rom做phh化处理
  cp -frp ./make/add_phh/system/* $systemdir/

  # 为phh化注册必要selinux上下文
  cat ./make/add_phh_plat_file_contexts/plat_file_contexts >> $systemdir/etc/selinux/plat_file_contexts

  # 为添加的文件注册必要的selinux上下文
  cat ./make/add_plat_file_contexts/plat_file_contexts >> $systemdir/etc/selinux/plat_file_contexts

  # 为所有rom的相机修改为aosp相机
  cd ./make/camera
  ./camera.sh
  cd $LOCALDIR

  # 系统种类检测
  cd ./make
  ./romtype.sh
  cd $LOCALDIR 

  # rom修补处理
  cd ./make/rom_make_patch
  ./make.sh 
  cd $LOCALDIR

  # oem_build合并
  cat ./make/add_build/add_oem_build >> $systemdir/build.prop

  # 为rom添加oem服务所依赖的hal接口
  rm -rf ./vintf
  mkdir ./vintf
  cp -frp $systemdir/etc/vintf/manifest.xml ./vintf/
  manifest="./vintf/manifest.xml"
  sed -i '/<\/manifest>/d' $manifest
  cat ./make/add_etc_vintf_patch/manifest_common >> $manifest
  cat ./make/add_etc_vintf_patch/manifest_custom >> $manifest
  echo "" >> $manifest
  echo "</manifest>" >> $manifest
  cp -frp $manifest $systemdir/etc/vintf/
  rm -rf ./vintf
  
  # fs数据整合
  cat ./make/add_fs/vndk_symlink_contexts >> $configdir/system_file_contexts
  cat ./make/add_fs/vndk_symlink_fs >> $configdir/system_fs_config  
  cat ./make/add_fs/bin_contexts >> $configdir/system_file_contexts 
  cat ./make/add_fs/bin_fs >> $configdir/system_fs_config 
  cat ./make/add_fs/etc_contexts >> $configdir/system_file_contexts 
  cat ./make/add_fs/etc_fs >> $configdir/system_fs_config 
  cat ./make/add_phh_fs/contexts >> $configdir/system_file_contexts
  cat ./make/add_phh_fs/fs >> $configdir/system_fs_config
  rm -rf ./make/lib_fs
  mkdir ./make/lib_fs

  lib_fs="$LOCALDIR/make/lib_fs/fs"
  lib_contexts="$LOCALDIR/make/lib_fs/contexts"
 
  rm -rf $lib_fs
  rm -rf $lib_contexts
  sed -i '/\/system\/system\/lib\//d' $configdir/system_file_contexts
  sed -i '/system\/system\/lib\//d' $configdir/system_fs_config
  sed -i '/\/system\/system\/lib64\//d' $configdir/system_file_contexts
  sed -i '/system\/system\/lib64\//d' $configdir/system_fs_config
  
  cd $systemdir/lib
  libs=$(find ./ -name "*")
  for lib in $libs ;do
    if [ -d "$lib" ];then
      echo "$lib" | sed 's#\./#/#g' | sed 's/^/&system\/system\/lib/g' | sed 's/$/& 0 0 0755/g' >> $lib_fs
      echo "$lib" | sed 's#\./#/#g' | sed 's/^/&\/system\/system\/lib/g' | sed 's/$/& u:object_r:system_lib_file:s0/g' >> $lib_contexts
    fi

    if [ -L "$lib" ];then
      echo "$lib" | sed 's#\./#/#g' | sed 's/^/&system\/system\/lib/g' | sed 's/$/& 0 0 0644/g' >> $lib_fs
      echo "$lib" | sed 's#\./#/#g' | sed 's/^/&\/system\/system\/lib/g' | sed 's/$/& u:object_r:system_lib_file:s0/g' >> $lib_contexts
    fi 

    if [ -f "$lib" ];then
      echo "$lib" | sed 's#\./#/#g' | sed 's/^/&system\/system\/lib/g' | sed 's/$/& 0 0 0644/g' >> $lib_fs
      echo "$lib" | sed 's#\./#/#g' | sed 's/^/&\/system\/system\/lib/g' | sed 's/$/& u:object_r:system_lib_file:s0/g' >> $lib_contexts
    fi 
  done
  cd $LOCALDIR

  cd $systemdir/lib64
  libs=$(find ./ -name "*")
  for lib in $libs ;do
    if [ -d "$lib" ];then
      echo "$lib" | sed 's#\./#/#g' | sed 's/^/&system\/system\/lib64/g' | sed 's/$/& 0 0 0755/g' >> $lib_fs
      echo "$lib" | sed 's#\./#/#g' | sed 's/^/&\/system\/system\/lib64/g' | sed 's/$/& u:object_r:system_lib_file:s0/g' >> $lib_contexts
    fi

    if [ -L "$lib" ];then
      echo "$lib" | sed 's#\./#/#g' | sed 's/^/&system\/system\/lib64/g' | sed 's/$/& 0 0 0644/g' >> $lib_fs
      echo "$lib" | sed 's#\./#/#g' | sed 's/^/&\/system\/system\/lib64/g' | sed 's/$/& u:object_r:system_lib_file:s0/g' >> $lib_contexts
    fi 

    if [ -f "$lib" ];then
      echo "$lib" | sed 's#\./#/#g' | sed 's/^/&system\/system\/lib64/g' | sed 's/$/& 0 0 0644/g' >> $lib_fs
      echo "$lib" | sed 's#\./#/#g' | sed 's/^/&\/system\/system\/lib64/g' | sed 's/$/& u:object_r:system_lib_file:s0/g' >> $lib_contexts
    fi 
  done
  cd $LOCALDIR
  sed -i '1d' $lib_fs
  sed -i '1d' $lib_contexts
  cat $lib_contexts >> $configdir/system_file_contexts
  cat $lib_fs >> $configdir/system_fs_config
}

function dynamic() {
  rm -rf ./make/add_dynamic_fs
  mkdir ./make/add_dynamic_fs

  # 复制fs至make目录
  rm -rf ./make/config
  mkdir ./make/config
  cp -frp $configdir/* ./make/config/
  mv ./make/config/system_fs_config ./make/config/system_fs
  mv ./make/config/system_file_contexts ./make/config/system_contexts
  if [ -L $systemdir/system_ext ] && [ -d $systemdir/../system_ext ];then
    mv ./make/config/system_ext_fs_config ./make/config/system_ext_fs 
    mv ./make/config/system_ext_file_contexts ./make/config/system_ext_contexts
  fi
  if [ -L $systemdir/product ] && [ -d $systemdir/../product ];then
    mv ./make/config/product_file_contexts ./make/config/product_contexts
    mv ./make/config/product_fs_config ./make/config/product_fs
  fi

  # 复制makefs至dynamic_fs目录
  cp -frp ./make/config/* ./make/add_dynamic_fs/
  mv ./make/add_dynamic_fs/system_contexts ./make/add_dynamic_fs/contexts
  mv ./make/add_dynamic_fs/system_fs ./make/add_dynamic_fs/fs
  rm -rf ./make/config

  merge_system_ext() {
    # 合并system_ext
    rm -rf $systemdir/system_ext
    rm -rf ./out/system_ext/lost+found
    mv ./out/system_ext $systemdir/

    # fs分段
    cat ./make/add_dynamic_fs/system_ext_fs | grep 'system_ext/lib' > ./make/add_dynamic_fs/system_ext_lib_fs
    sed -i '/system_ext\/lib/d' ./make/add_dynamic_fs/system_ext_fs
    cat ./make/add_dynamic_fs/system_ext_lib_fs | grep '0 0 0644 /system_ext' > ./make/add_dynamic_fs/system_ext_symlink_fs
    sed -i '/0 0 0644 \/system_ext/d' ./make/add_dynamic_fs/system_ext_lib_fs
 
    ## fs数据处理
    sed -i '1d' ./make/add_dynamic_fs/system_ext_contexts
    sed -i '1d' ./make/add_dynamic_fs/system_ext_fs
 
    # contexts
    sed -i 's#/system_ext #/system/system/system_ext #g' ./make/add_dynamic_fs/system_ext_contexts
    sed -i 's#/system_ext/#/system/system/system_ext/#g' ./make/add_dynamic_fs/system_ext_contexts
    sed -i '/build/d' ./make/add_dynamic_fs/system_ext_contexts
    echo "/system/system/system_ext/build\.prop u:object_r:system_file:s0" >> ./make/add_dynamic_fs/system_ext_contexts

    # fs
    sed -i 's#system_ext #system/system/system_ext #g' ./make/add_dynamic_fs/system_ext_fs
    sed -i 's#system_ext/#system/system/system_ext/#g' ./make/add_dynamic_fs/system_ext_fs
 
    # lib_fs
    sed -i 's#system_ext/#system/system/system_ext/#g' ./make/add_dynamic_fs/system_ext_lib_fs

    # symlink_fs
    sed -i 's#/system_ext/#/system/system_ext/#g' ./make/add_dynamic_fs/system_ext_symlink_fs
    sed -i 's#system_ext/#system/system/system_ext/#g' ./make/add_dynamic_fs/system_ext_symlink_fs
    sed -i 's#/system/system/system/system_ext/#/system/system_ext/#g' ./make/add_dynamic_fs/system_ext_symlink_fs

    # 合并system_ext_fs
    cat ./make/add_dynamic_fs/system_ext_contexts >> ./make/add_dynamic_fs/contexts
    cat ./make/add_dynamic_fs/system_ext_symlink_fs >> ./make/add_dynamic_fs/fs
    cat ./make/add_dynamic_fs/system_ext_lib_fs >> ./make/add_dynamic_fs/fs
    cat ./make/add_dynamic_fs/system_ext_fs >> ./make/add_dynamic_fs/fs
  }

  merge_product() {
    # 合并product
    rm -rf $systemdir/product
    rm -rf ./out/product/lost+found
    mv ./out/product $systemdir/
 
    # fs分段
    cat ./make/add_dynamic_fs/product_fs | grep 'product/lib' > ./make/add_dynamic_fs/product_lib_fs
    sed -i '/product\/lib/d' ./make/add_dynamic_fs/product_fs
    cat ./make/add_dynamic_fs/product_lib_fs | grep '0 0 0644 /product' > ./make/add_dynamic_fs/product_symlink_fs
    sed -i '/0 0 0644 \/product/d' ./make/add_dynamic_fs/product_lib_fs
 
    # fs数据处理
    sed -i '1d' ./make/add_dynamic_fs/product_contexts
    sed -i '1d' ./make/add_dynamic_fs/product_fs
 
    # contexts
    sed -i 's#/product #/system/system/product #g' ./make/add_dynamic_fs/product_contexts
    sed -i 's#/product/#/system/system/product/#g' ./make/add_dynamic_fs/product_contexts
    sed -i '/build/d' ./make/add_dynamic_fs/product_contexts
    echo "/system/system/product/build\.prop u:object_r:system_file:s0" >> ./make/add_dynamic_fs/product_contexts

    # fs
    sed -i 's#product #system/system/product #g' ./make/add_dynamic_fs/product_fs
    sed -i 's#product/#system/system/product/#g' ./make/add_dynamic_fs/product_fs
 
    # lib_fs
    sed -i 's#product/#system/system/product/#g' ./make/add_dynamic_fs/product_lib_fs

    # symlink_fs
    sed -i 's#/product/#/system/product/#g' ./make/add_dynamic_fs/product_symlink_fs
    sed -i 's#product/#system/system/product/#g' ./make/add_dynamic_fs/product_symlink_fs
    sed -i 's#/system/system/system/product/#/system/product/#g' ./make/add_dynamic_fs/product_symlink_fs

    # 合并product_fs
    cat ./make/add_dynamic_fs/product_contexts >> ./make/add_dynamic_fs/contexts
    cat ./make/add_dynamic_fs/product_symlink_fs >> ./make/add_dynamic_fs/fs
    cat ./make/add_dynamic_fs/product_lib_fs >> ./make/add_dynamic_fs/fs
    cat ./make/add_dynamic_fs/product_fs >> ./make/add_dynamic_fs/fs
  }
  if [ -L $systemdir/system_ext ] && [ -d $systemdir/../system_ext ];then
    merge_system_ext
  fi
  if [ -L $systemdir/product ] && [ -d $systemdir/../product ];then
    merge_product
  fi

  # 替换原fs
  mv ./make/add_dynamic_fs/contexts ./make/add_dynamic_fs/system_file_contexts 
  mv ./make/add_dynamic_fs/fs ./make/add_dynamic_fs/system_fs_config
  cp -frp ./make/add_dynamic_fs/system_file_contexts $configdir/system_file_contexts
  cp -frp ./make/add_dynamic_fs/system_fs_config $configdir/system_fs_config  
}

function make_Aonly() {

  echo "正在制造A-only"
  
  # 为所有rom去除ab特性
  ## build
  sed -i '/system_root_image/d' $systemdir/build.prop
  sed -i '/ro.build.ab_update/d' $systemdir/build.prop
  sed -i '/sar/d' $systemdir/build.prop

  ## 删除多余文件
  rm -rf $systemdir/etc/init/update_engine.rc
  rm -rf $systemdir/etc/init/update_verifier.rc
  rm -rf $systemdir/etc/update_engine
  rm -rf $systemdir/bin/update_engine
  rm -rf $systemdir/bin/update_verifier

  # 修补oem的rc
  oemrc_files=$(ls $systemdir/../ | grep ".rc$")
  for oemrc in $oemrc_files ;do
    new_oemrc=$(echo "${oemrc%.*}" | sed 's/$/&-treble.rc/g')
    cp -fr $systemdir/../$oemrc $systemdir/etc/init/$new_oemrc
    # 清理new_oemrc中的错误导入
    for i in $systemdir/etc/init/$new_oemrc ;do 
      echo "$(cat $i | grep -v "^import")" > $i 
    done
    # 为新的rc添加fs数据
    echo "/system/system/etc/init/$new_oemrc u:object_r:system_file:s0" >> $configdir/system_file_contexts
    echo "system/system/etc/init/$new_oemrc 0 0 0644" >> $configdir/system_fs_config
  done

  # 为所有rom禁用/system/etc/init/ueventd.rc
  rm -rf $systemdir/etc/init/ueventd.rc

  # 为所有rom改用内核自带的init.usb.rc
  rm -rf $systemdir/etc/init/hw/init.usb.rc
  rm -rf $systemdir/etc/init/hw/init.usb.configfs.rc
  sed -i '/\/system\/etc\/init\/hw\/init.usb.rc/d' $systemdir/etc/init/hw/init.rc
  sed -i '/\/system\/etc\/init\/hw\/init.usb.configfs.rc/d' $systemdir/etc/init/hw/init.rc

  # 去除init.environ.rc重复导入
  sed -i '/\/init.environ.rc/d' $systemdir/etc/init/hw/init.rc
  
  modify_init_environ() {
    # 修改init.environ.rc
    sed -i 's/on early\-init/on init/g' $systemdir/etc/init/init.environ-treble.rc
    sed -i '/ANDROID\_BOOTLOGO/d' $systemdir/etc/init/init.environ-treble.rc
    sed -i '/ANDROID\_ROOT/d' $systemdir/etc/init/init.environ-treble.rc
    sed -i '/ANDROID\_ASSETS/d' $systemdir/etc/init/init.environ-treble.rc
    sed -i '/ANDROID\_DATA/d' $systemdir/etc/init/init.environ-treble.rc
    sed -i '/ANDROID\_STORAGE/d' $systemdir/etc/init/init.environ-treble.rc
    sed -i '/EXTERNAL\_STORAGE/d' $systemdir/etc/init/init.environ-treble.rc
    sed -i '/ASEC\_MOUNTPOINT/d' $systemdir/etc/init/init.environ-treble.rc
  }
  if [ -f $systemdir/etc/init/init.environ-treble.rc ];then
    modify_init_environ
  else
    echo "此rom不支持制造A-only"
    exit  
  fi

  # 为老设备迁移 /system/etc/hw/*.rc 至 /system/etc/init/
  old_rc_flies=$(ls $systemdir/etc/init/hw)
  for old_rc in $old_rc_flies ;do
    new_rc=$(echo "${old_rc%.*}" | sed 's/$/&-treble.rc/g')
    cp -frp $systemdir/etc/init/hw/$old_rc $systemdir/etc/init/$new_rc
    echo "/system/system/etc/init/$new_rc u:object_r:system_file:s0" >> $configdir/system_file_contexts
    echo "system/system/etc/init/$new_rc 0 0 0644" >> $configdir/system_fs_config
  done 
  
  # 添加启动A-only必备文件 
  cp -frp ./make/init_A/system/* $systemdir

  # fs数据整合
  cat ./make/add_fs/init-A_fs >> $configdir/system_fs_config
  cat ./make/add_fs/init-A_contexts >> $configdir/system_file_contexts
}

function fix_bug() {
  # 亮度修复
  read -p "是否启用亮度修复(y/n): " light
 
  case $light in
    "y") 
      echo "启用亮度修复"
      cp -frp $(find ./out/system/ -type f -name 'services.jar') ./fixbug/light_fix/
      cd ./fixbug/light_fix
      ./brightness_fix.sh
      dist="$(find ./services.jar.out/ -type d -name 'dist')"
      if [ ! $dist = "" ];then
        cp -frp $dist/services.jar $systemdir/framework/
      fi
      cd $LOCALDIR
      ;;
    "n")
      echo "跳过亮度修复"
      ;;
    *)
      echo "error！"
      exit
      ;;  
  esac

  # bug修复
  read -p "是否修复启用bug修复(y/n): " fixbug
  
  case $fixbug in
    "y")
      echo "启用bug修复"
      cd ./fixbug
      ./fixbug.sh
      cd $LOCALDIR
      ;;
    "n")
      echo "跳过bug修复"
      ;;
    *)
      echo "error！"
      exit
      ;;        
  esac
}

make_type=$1

if [[ -L $systemdir/system_ext && -d $systemdir/../system_ext ]] \
|| [[ -L $systemdir/product && -d $systemdir/../product ]];then
  echo "检测到当前为动态原包，启用动态原包处理"
  if [ -e ./system_ext.img ];then
    echo "解压system_ext.img中..."
    python3 $bin/imgextractor.py ./system_ext.img ./out
    if [ $? = "1" ];then
      echo "system_ext.img解压失败！"
      exit
    else
      echo "解压完成"
    fi
  fi 
  if [ -e ./product.img ];then
    echo "解压product.img中..."
    python3 $bin/imgextractor.py ./product.img ./out
    if [ $? = "1" ];then
      echo "product.img解压失败！"
      exit
    else
      echo "解压完成"
    fi
  fi
  dynamic
fi

if [ -L $systemdir/vendor ];then
  echo "当前为正常pt 启用正常处理方案"
  echo "SGSI化处理开始"
  case $make_type in
    "A"|"a")  
      normal
      make_Aonly
      echo "SGSI化处理完成"
      fix_bug
      ./makeimg.sh "A"
      exit
      ;;
    "AB"|"ab")
      normal
      echo "SGSI化处理完成"
      fix_bug  
      ./makeimg.sh "AB"
      exit
      ;;
    *)
      echo "error!"
      exit
      ;;      
  esac  
fi
