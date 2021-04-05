#!/bin/bash

# Copyright (C) 2021 Xiaoxindada <2245062854@qq.com>

LOCALDIR=`cd "$( dirname $0 )" && pwd`
cd $LOCALDIR
source ./bin.sh

Usage() {
cat <<EOT
Usage:
$0 <Build Type> <OS Type> [Other args]
  Build Type: [--AB|--ab] or [-A|-a|--a-only]
  OS Type: Rom OS type to build

  Other args:
    [--fix-bug]: Fix bugs in Rom
EOT
}

case $1 in
  "--AB"|"--ab")
    build_type="--ab"
    ;;
  "-A"|"-a"|"--a-only")
    build_type="--a-only"
    echo "暂不支持A-only"
    exit
    ;;
  "-h"|"--help")
    Usage
    exit
    ;;    
  *)
    Usage
    exit
    ;;
esac

if [ $# -lt 2 ];then
  Usage
  exit
fi

os_type="$2"
build_type="$build_type"
bug_fix="false"
use_config="_config"
other_args=""
systemdir="$LOCALDIR/out/system/system"
configdir="$LOCALDIR/out/config"
shift 2

if ! (cat ./make/rom_support_list.txt | grep -qo "$os_type");then
  echo "此rom未支持!"
  echo "支持的rom有:"
  cat ./make/rom_support_list.txt
  exit
fi

function normal() {
  # 为所有rom修改ramdisk层面的system
  echo "正在修改system外层"
  ramdisk_modify() {
    rm -rf "$systemdir/../persist"
    rm -rf "$systemdir/../bt_firmware"
    rm -rf "$systemdir/../firmware"
    rm -rf "$systemdir/../cache"
    mkdir -p "$systemdir/../persist"
    mkdir -p "$systemdir/../cache"
    ln -s "/vendor/bt_firmware" "$systemdir/../bt_firmware"
    ln -s "/vendor/firmware" "$systemdir/../firmware"

    if [ -f $configdir/system_file_contexts ];then
      sed -i '/\/system\/persist /d' $configdir/system_file_contexts
      sed -i '/\/system\/bt_firmware /d' $configdir/system_file_contexts
      sed -i '/\/system\/firmware /d' $configdir/system_file_contexts
      sed -i '/\/system\/cache /d' $configdir/system_file_contexts

      echo "/system/persist u:object_r:mnt_vendor_file:s0" >> $configdir/system_file_contexts
      echo "/system/bt_firmware u:object_r:bt_firmware_file:s0" >> $configdir/system_file_contexts
      echo "/system/firmware u:object_r:firmware_file:s0" >> $configdir/system_file_contexts
      echo "/system/cache u:object_r:cache_file:s0" >> $configdir/system_file_contexts
    fi

    if [ -f $configdir/system_fs_config ];then
      sed -i '/system\/persist /d' $configdir/system_fs_config
      sed -i '/system\/bt_firmware /d' $configdir/system_fs_config
      sed -i '/system\/firmware /d' $configdir/system_fs_config
      sed -i '/system\/cache /d' $configdir/system_fs_config

      echo "system/persist 0 0 0755" >> $configdir/system_fs_config
      echo "system/bt_firmware 0 0 0644" >> $configdir/system_fs_config
      echo "system/firmware 0 0 0644" >> $configdir/system_fs_config
      echo "system/cache 1000 2001 0770" >> $configdir/system_fs_config
    fi
  }
  ramdisk_modify
  echo "修改完成"
 
  # apex_vndk调用处理
  cd ./make/apex_vndk_start
  ./make.sh
  cd $LOCALDIR 

  echo "正在进行其他处理"

  # 重置manifest_custom
  true > ./make/add_etc_vintf_patch/manifest_custom
  echo "" >> ./make/add_etc_vintf_patch/manifest_custom
  echo "<!-- oem自定义接口 -->" >> ./make/add_etc_vintf_patch/manifest_custom

  true > ./make/add_build/add_oem_build
  echo "" >> ./make/add_build/add_oem_build
  echo "# oem厂商自定义属性" >> ./make/add_build/add_oem_build
 
  # 为所有rom添加抓logcat的文件
  cp -frp ./make/add_logcat/system/* $systemdir/

  # 为所有rom做usb通用化
  cp -frp ./make/aosp_usb/* $systemdir/etc/init/hw/

  # 为所有rom做selinux通用化处理
  sed -i "/typetransition location_app/d" $systemdir/etc/selinux/plat_sepolicy.cil
  #sed -i '/u:object_r:vendor_default_prop:s0/d' $systemdir/etc/selinux/plat_property_contexts
  sed -i '/software.version/d'  $systemdir/etc/selinux/plat_property_contexts
  #sed -i '/sys.usb/d' $systemdir/etc/selinux/plat_property_contexts
  sed -i '/ro.build.fingerprint    u:object_r:fingerprint_prop:s0/d' $systemdir/etc/selinux/plat_property_contexts

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
    sed -i 's/ro.sf.lcd/#&/' $systemdir/product/etc/build.prop
    sed -i 's/ro.sf.lcd/#&/' $systemdir/system_ext/etc/build.prop    
  
    # 为所有rom清理一些无用属性
    sed -i '/vendor.display/d' $systemdir/build.prop
    sed -i '/vendor.perf/d' $systemdir/build.prop
    sed -i '/debug.sf/d' $systemdir/build.prop
    sed -i '/debug.sf/d' $systemdir/product/etc/build.prop
    sed -i '/persist.sar.mode/d' $systemdir/build.prop
    sed -i '/opengles.version/d' $systemdir/build.prop
    sed -i '/actionable_compatible_property.enabled/d' $systemdir/build.prop

    # 为所有rom禁用caf media.setting
    sed -i '/media.settings.xml/d' $systemdir/build.prop

    # 为所有rom添加必要的通用属性
    sed -i '/system_root_image/d' $systemdir/build.prop
    sed -i '/ro.control_privapp_permissions/d' $systemdir/build.prop
    sed -i '/ro.control_privapp_permissions/d' $systemdir/product/etc/build.prop
    sed -i '/ro.control_privapp_permissions/d' $systemdir/system_ext/etc/build.prop  
    cat ./make/add_build/add_build >> $systemdir/build.prop
    cat ./make/add_build/add_product_build >> $systemdir/product/etc/build.prop
    cat ./make/add_build/add_system_ext_build >> $systemdir/system_ext/etc/build.prop

    # Disable bpfloader
    rm -rf $systemdir/etc/init/bpfloader.rc
    echo "bpf.progs_loaded=1" >> $systemdir/product/etc/build.prop

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

  # 为所有rom禁用 reboot_on_failure 检查
  sed -i "/reboot_on_failure/d" $systemdir/etc/init/hw/init.rc

  # 为所有rom还原fstab.postinstall
  find  ./out/system/ -type f -name "fstab.postinstall" | xargs rm -rf
  rm -rf $systemdir/etc/init/cppreopts.rc    
  cp -frp ./make/fstab/system/* $systemdir
  sed -i '/fstab\\.postinstall/d' $configdir/system_file_contexts
  sed -i '/fstab.postinstall/d' $configdir/system_fs_config
  cat ./make/fstab/fstab_contexts >> $configdir/system_file_contexts
  cat ./make/fstab/fstab_fs >> $configdir/system_fs_config
  
  # 添加缺少的libs
  cp -frpn ./make/add_libs/system/* $systemdir
 
  # 为所有rom启用debug调试
  sed -i 's/persist.sys.usb.config=none/persist.sys.usb.config=adb/g' $systemdir/build.prop
  sed -i 's/ro.debuggable=0/ro.debuggable=1/g' $systemdir/build.prop
  sed -i 's/ro.adb.secure=1/ro.adb.secure=0/g' $systemdir/build.prop
  echo "ro.force.debuggable=1" >> $systemdir/build.prop
  
  sed -i 's/persist.sys.usb.config=none/persist.sys.usb.config=adb/g' $systemdir/system_ext/etc/build.prop
  sed -i 's/ro.debuggable=0/ro.debuggable=1/g' $systemdir/system_ext/etc/build.prop
  sed -i 's/ro.adb.secure=1/ro.adb.secure=0/g' $systemdir/system_ext/etc/build.prop
  echo "ro.force.debuggable=1" >> $systemdir/system_ext/etc/build.prop

  sed -i 's/persist.sys.usb.config=none/persist.sys.usb.config=adb/g' $systemdir/product/etc/build.prop
  sed -i 's/ro.debuggable=0/ro.debuggable=1/g' $systemdir/product/etc/build.prop
  sed -i 's/ro.adb.secure=1/ro.adb.secure=0/g' $systemdir/product/etc/build.prop
  echo "ro.force.debuggable=1" >> $systemdir/product/etc/build.prop


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
  #cd ./make/camera
  #./camera.sh
  #cd $LOCALDIR

  # 系统种类检测
  cd ./make
  ./romtype.sh "$os_type"
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
}

function make_Aonly() {

  echo "正在制造A-onlay"
  
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

  # 为所有rom禁用/system/etc/ueventd.rc
  rm -rf $systemdir/etc/ueventd.rc

  # 为所有rom改用内核自带的init.usb.rc
  #rm -rf $systemdir/etc/init/hw/init.usb.rc
  #rm -rf $systemdir/etc/init/hw/init.usb.configfs.rc
  #sed -i '/\/system\/etc\/init\/hw\/init.usb.rc/d' $systemdir/etc/init/hw/init.rc
  #sed -i '/\/system\/etc\/init\/hw\/init.usb.configfs.rc/d' $systemdir/etc/init/hw/init.rc

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
    # 为新的rc添加fs数据
    echo "/system/system/etc/init/$new_rc u:object_r:system_file:s0" >> $configdir/system_file_contexts
    echo "system/system/etc/init/$new_rc 0 0 0644" >> $configdir/system_fs_config  
  done 
  
  # 添加启动A-only必备文件 
  cp -frp ./make/init_A/system/* $systemdir/

  # 修补apex-setup.rc
  cat $systemdir/etc/init/apex-setup.rc >> $systemdir/etc/init/add_apex-setup.rc
  mv -f $systemdir/etc/init/add_apex-setup.rc $systemdir/etc/init/apex-setup.rc

  # permissive启动延后
  sed -i "s/on early\-init/on init/" $systemdir/etc/init/permissiver.rc

  # apex_vndk调用处理
  cd ./make/apex_vndk_start
  ./make_A.sh
  cd $LOCALDIR 
}

function fix_bug() {
    echo "启用bug修复"
    cd ./fixbug
    ./fixbug.sh "$os_type"
    cd $LOCALDIR
}

if [[ "$1" = "--fix-bug" ]];then
  other_args+="--fix-bug"
  shift
fi

if (echo ${other_args} | grep -qo "fix-bug");then
  bug_fix="true"
fi

rm -rf ./SGSI

# simg2img
./simg2img.sh "$LOCALDIR"

# 分区挂载
#./mount_partition.sh
cd $LOCALDIR

# image提取
./image_extract.sh

if [[ -d $systemdir/../system_ext && -L $systemdir/system_ext ]] \
|| [[ -d $systemdir/../product && -L $systemdir/product ]];then
  echo "检测到当前为动态分区"
  ./partition_merge.sh
fi

if [[ ! -d $systemdir/product ]];then
  echo "$systemdir/product目录不存在！"
  exit
elif [[ ! -d $systemdir/system_ext ]];then
  echo "$systemdir/system_ext目录不存在！"
  exit
fi

model="$(cat $systemdir/build.prop | grep 'model')"
echo "当前原包机型为:"
echo "$model"

if [ -L $systemdir/vendor ];then
  echo "当前为正常pt 启用正常处理方案"
  echo "SGSI化处理开始"
  case $build_type in
    "-A"|"-a"|"--a-only")
      echo "A"
      normal
      make_Aonly
      # fs数据整合
      ./make/apex_flat/add_apex_fs.sh
      ./make/add_repack_fs.sh
      echo "SGSI化处理完成"
      if [ $bug_fix = "true" ];then
        fix_bug
      fi
      ./makeimg.sh "--a-only${use_config}"
      exit
      ;;
      "--AB"|"--ab")
      echo "AB"
      normal
      # fs数据整合
      ./make/apex_flat/add_apex_fs.sh
      ./make/add_repack_fs.sh
      # 清理fs空行
      for i in $(ls $configdir);do
        if [ -f $configdir/$i ];then
          sed -i '/^\s*$/d' $configdir/$i
        fi
      done
      echo "SGSI化处理完成"
      if [ $bug_fix = "true" ];then
        fix_bug
      fi
      ./makeimg.sh "--ab${use_config}"
      exit
      ;;
    esac 
fi
