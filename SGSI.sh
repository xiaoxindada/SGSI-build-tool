#!/bin/bash

# Copyright (C) 2021 Xiaoxindada <2245062854@qq.com>
set -e

LOCALDIR=`cd "$( dirname ${BASH_SOURCE[0]} )" && pwd`
cd $LOCALDIR
source ./bin.sh
source ./language_helper.sh

Usage() {
cat <<EOT
Usage:
$0 <Build Type> <OS Type> [Other args]
  Build Type: [--AB|--ab] or [-A|-a|--a-only]
  OS Type: Rom OS type to build

  Other args:
    [--fix-bug]: Fix bugs in ROM
EOT
}

case $1 in
  "--AB"|"--ab")
    build_type="--ab"
    ;;
  "-A"|"-a"|"--a-only")
    build_type="--a-only"
    echo "$NOTSUPPAONLY"
    exit 1
    ;;
  "-h"|"--help")
    Usage
    exit 1
    ;;    
  *)
    Usage
    exit 1
    ;;
esac

if [ $# -lt 2 ];then
  Usage
  exit 1
fi

os_type="$2"
build_type="$build_type"
bug_fix="false"
use_config="_config"
other_args=""
systemdir="$TARGETDIR/system/system"
configdir="$TARGETDIR/config"
shift 2

if ! (cat ./make/rom_support_list.txt | grep -qo "$os_type");then
  echo $UNSUPPORTED_ROM
  echo $SUPPORTED_ROM_LIST
  cat ./make/rom_support_list.txt
  exit 1
fi

function normal() {
  # Process ramdisk's system for all rom
  echo "$PROCESSING_RAMDISK_SYSTEM"
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
  echo "$PROCESS_SUCCESS"
 
  # Common apex_vndk process
  cd ./make/apex_vndk_start
  ./make.sh
  cd $LOCALDIR 

  echo "$OTHER_PROCESSINGS"

  # Reset manifest_custom
  true > ./make/add_etc_vintf_patch/manifest_custom
  echo "" >> ./make/add_etc_vintf_patch/manifest_custom
  echo "<!-- oem hal -->" >> ./make/add_etc_vintf_patch/manifest_custom

  true > ./make/add_build/oem_prop
  echo "" >> ./make/add_build/oem_prop
  echo "# oem common prop" >> ./make/add_build/oem_prop
 
  # Add logcat support
  cp -frp ./make/add_logcat/system/* $systemdir/

  # Modify USB State
  cp -frp ./make/aosp_usb/* $systemdir/etc/init/hw/

  # Patch SELinux to ensure maximum device compatibility
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
  # Fix Device Properties for qssi
    qssi() {
      cat $systemdir/build.prop | grep -qo 'qssi'
    }
    if qssi ;then
      echo "$QSSI_DETECTED"
      echo "$DEVICE_PROP_FIX_STARTED"
      brand=$(cat $TARGETDIR/vendor/build.prop | grep 'ro.product.vendor.brand')
      device=$(cat $TARGETDIR/vendor/build.prop | grep 'ro.product.vendor.device')
      manufacturer=$(cat $TARGETDIR/vendor/build.prop | grep 'ro.product.vendor.manufacturer')
      model=$(cat $TARGETDIR/vendor/build.prop | grep 'ro.product.vendor.model')
      mame=$(cat $TARGETDIR/vendor/build.prop | grep 'ro.product.vendor.name')
  
      echo "$CURR_DEVICE_PROP:"
      echo "$brand"
      echo "$device"
      echo "$manufacturer"
      echo "$model"
      echo "$mame"

      echo "$FIXING_STR"
      sed -i '/ro.product.system./d' $systemdir/build.prop
      echo "" >> $systemdir/build.prop
      echo "# Device Settings" >> $systemdir/build.prop
      echo "$brand" >> $systemdir/build.prop
      echo "$device" >> $systemdir/build.prop
      echo "$manufacturer" >> $systemdir/build.prop
      echo "$model" >> $systemdir/build.prop
      echo "$mame" >> $systemdir/build.prop
      sed -i 's/ro.product.vendor./ro.product.system./g' $systemdir/build.prop
      echo "$FIX_FINISHED_STR"
    fi
 
    # Enable auto-adapting dpi
    sed -i 's/ro.sf.lcd/#&/' $systemdir/build.prop
    sed -i 's/ro.sf.lcd/#&/' $systemdir/product/etc/build.prop
    sed -i 's/ro.sf.lcd/#&/' $systemdir/system_ext/etc/build.prop    
  
    # Cleanup properties
    sed -i '/vendor.display/d' $systemdir/build.prop
    sed -i '/vendor.perf/d' $systemdir/build.prop
    sed -i '/debug.sf/d' $systemdir/build.prop
    sed -i '/debug.sf/d' $systemdir/product/etc/build.prop
    sed -i '/ro.sys.sdcardfs/d' $systemdir/product/etc/build.prop
    sed -i '/persist.sar.mode/d' $systemdir/build.prop
    sed -i '/opengles.version/d' $systemdir/build.prop
    sed -i '/actionable_compatible_property.enabled/d' $systemdir/build.prop

    # Disable caf media.setting
    sed -i '/media.settings.xml/d' $systemdir/build.prop

    # Add common properties
    sed -i '/system_root_image/d' $systemdir/build.prop
    sed -i '/ro.control_privapp_permissions/d' $systemdir/build.prop
    sed -i '/ro.control_privapp_permissions/d' $systemdir/product/etc/build.prop
    sed -i '/ro.control_privapp_permissions/d' $systemdir/system_ext/etc/build.prop  
    cat ./make/add_build/system_prop >> $systemdir/build.prop
    cat ./make/add_build/product_prop >> $systemdir/product/etc/build.prop
    cat ./make/add_build/system_ext_prop >> $systemdir/system_ext/etc/build.prop

    # Disable bpfloader
    rm -rf $systemdir/etc/init/bpfloader.rc
    echo ""  >> $systemdir/product/etc/build.prop
    echo "# Disable bpfloader" >> $systemdir/product/etc/build.prop
    echo "bpf.progs_loaded=1" >> $systemdir/product/etc/build.prop

    # Enable HW Mainkeys
    mainkeys() {
      grep -q 'qemu.hw.mainkeys=' $systemdir/build.prop
    }  
    if mainkeys ;then
      sed -i 's/qemu.hw.mainkeys\=1/qemu.hw.mainkeys\=0/g' $systemdir/build.prop
    else
      echo "" >> $systemdir/build.prop
      echo "# Enable HW Mainkeys" >> $systemdir/build.prop
      echo "qemu.hw.mainkeys=0" >> $systemdir/build.prop
    fi

    # Hack qssi property read order
    source_order() {
      grep -q 'ro.product.property_source_order=' $systemdir/build.prop
    }
    if source_order ;then
      sed -i '/ro.product.property\_source\_order\=/d' $systemdir/build.prop
      echo "" >> $systemdir/build.prop
      echo "# Property Read Order" >> $systemdir/build.prop
      echo "ro.product.property_source_order=system,product,system_ext,vendor,odm" >> $systemdir/build.prop
    fi
  }
  build_modify

  # Diable reboot_on_failure Check
  sed -i "/reboot_on_failure/d" $systemdir/etc/init/hw/init.rc
  sed -i "/reboot_on_failure/d" $systemdir/etc/init/apexd.rc

  # Revert fstab.postinstall to gsi state
  find $systemdir/../ -type f -name "fstab.postinstall" | xargs rm -rf
  rm -rf $systemdir/etc/init/cppreopts.rc    
  cp -frp ./make/fstab/system/* $systemdir
  sed -i '/fstab\\.postinstall/d' $configdir/system_file_contexts
  sed -i '/fstab.postinstall/d' $configdir/system_fs_config
  cat ./make/fstab/fstab_contexts >> $configdir/system_file_contexts
  cat ./make/fstab/fstab_fs >> $configdir/system_fs_config
  
  # Add missing libs
  cp -frpn ./make/add_libs/system/* $systemdir
 
  # Enable debug feature
  sed -i 's/persist.sys.usb.config=none/persist.sys.usb.config=adb/g' $systemdir/build.prop
  sed -i 's/ro.debuggable=0/ro.debuggable=1/g' $systemdir/build.prop
  sed -i 's/ro.adb.secure=1/ro.adb.secure=0/g' $systemdir/build.prop
  
  sed -i 's/persist.sys.usb.config=none/persist.sys.usb.config=adb/g' $systemdir/system_ext/etc/build.prop
  sed -i 's/ro.debuggable=0/ro.debuggable=1/g' $systemdir/system_ext/etc/build.prop
  sed -i 's/ro.adb.secure=1/ro.adb.secure=0/g' $systemdir/system_ext/etc/build.prop

  sed -i 's/persist.sys.usb.config=none/persist.sys.usb.config=adb/g' $systemdir/product/etc/build.prop
  sed -i 's/ro.debuggable=0/ro.debuggable=1/g' $systemdir/product/etc/build.prop
  sed -i 's/ro.adb.secure=1/ro.adb.secure=0/g' $systemdir/product/etc/build.prop
  echo "" >> $systemdir/product/etc/build.prop
  echo "# force debug" >> $systemdir/product/etc/build.prop
  echo "ro.force.debuggable=1" >> $systemdir/product/etc/build.prop


  # Remove qti_permissions
  find $systemdir -type f -name "qti_permissions.xml" | xargs rm -rf

  # Remove firmware
  find $systemdir -type d -name "firmware" | xargs rm -rf

  # Remove avb
  find $systemdir -type d -name "avb" | xargs rm -rf
  
  # Remove com.qualcomm.location
  find $systemdir -type d -name "com.qualcomm.location" | xargs rm -rf

  # Remove some useless files
  rm -rf $systemdir/../verity_key
  rm -rf $systemdir/../init.recovery*
  rm -rf $systemdir/recovery-from-boot.*

  # Patch System
  cp -frp ./make/system_patch/system/* $systemdir/

  # Patch system to phh system
  cp -frp ./make/add_phh/system/* $systemdir/

  # Register selinux contexts related by phh system
  cat ./make/add_phh_plat_file_contexts/plat_file_contexts >> $systemdir/etc/selinux/plat_file_contexts

  # Register selinux contexts related by added files
  cat ./make/add_plat_file_contexts/plat_file_contexts >> $systemdir/etc/selinux/plat_file_contexts

  # Replace to AOSP Camera
  #cd ./make/camera
  #./camera.sh
  #cd $LOCALDIR

  # Detect ROM Type
  cd ./make
  ./romtype.sh "$os_type"
  cd $LOCALDIR

  # ROM Patch Process
  cd ./make/rom_make_patch
  ./make.sh
  cd $LOCALDIR

  # Add oem_build
  cat ./make/add_build/oem_prop >> $systemdir/build.prop

  # Add OEM HAL Manifest Interfaces
  manifest_tmp="$TARGETDIR/vintf/manifest.xml"
  rm -rf $(dirname $manifest_tmp)
  mkdir -p $(dirname $manifest_tmp)
  cp -frp $systemdir/etc/vintf/manifest.xml $(dirname $manifest_tmp)
  sed -i '/<\/manifest>/d' $manifest_tmp
  cat ./make/add_etc_vintf_patch/manifest_common >> $manifest_tmp
  cat ./make/add_etc_vintf_patch/manifest_custom >> $manifest_tmp
  echo "" >> $manifest_tmp
  echo "</manifest>" >> $manifest_tmp
  cp -frp $manifest_tmp $systemdir/etc/vintf/
  rm -rf $(dirname $manifest_tmp)
  cp -frp ./make/add_etc_vintf_patch/manifest_custom $TARGETDIR/manifest_custom
  true > ./make/add_etc_vintf_patch/manifest_custom
  echo "" >> ./make/add_etc_vintf_patch/manifest_custom
  echo "<!-- oem hal -->" >> ./make/add_etc_vintf_patch/manifest_custom
}

function fix_bug() {
    echo "$START_BUG_FIX"
    cd ./fixbug
    ./fixbug.sh "$os_type"
    cd $LOCALDIR
}

if (echo $@ | grep -qo -- "--fix-bug") ;then
  other_args+=" --fix-bug"
fi

rm -rf ./SGSI

# Sparse Image To Raw Image
./simg2img.sh "$IMAGESDIR"

# Mount Partitions
#./mount_partition.sh
cd $LOCALDIR

# Extract Image
./image_extract.sh

if [[ -d $systemdir/../system_ext && -L $systemdir/system_ext ]] \
|| [[ -d $systemdir/../product && -L $systemdir/product ]];then
  echo "$DYNAMIC_PARTITION_DETECTED"
  ./partition_merge.sh
fi

if [[ ! -d $systemdir/product ]];then
  echo "$systemdir/product $DIR_NOT_FOUND_STR!"
  exit 1
elif [[ ! -d $systemdir/system_ext ]];then
  echo "$systemdir/system_ext $DIR_NOT_FOUND_STR!"
  exit 1
fi

model="$(cat $systemdir/build.prop | grep 'model')"
echo "$CURR_DEVICE_PROPS:"
echo "$model"

if [ -L $systemdir/vendor ];then
  echo "$IS_NORMAL_PT"
  echo "$START_NOR_PROCESS_PLAN"
  case $build_type in
      "--AB"|"--ab")
      echo "AB"
      normal
      # Merge FS DATA
      cd ./make/apex_flat
      ./add_apex_fs.sh
      cd $LOCALDIR
      cd ./make
      ./add_repack_fs.sh
      cd $LOCALDIR
      # Format output
      for i in $(ls $configdir);do
        if [ -f $configdir/$i ];then
          sort -u $configdir/$i > $configdir/${i}-tmp
          mv -f $configdir/${i}-tmp $configdir/$i
          sed -i '/^\s*$/d' $configdir/$i
        fi
      done
      echo "$SGSI_IFY_SUCCESS"
      if (echo $other_args | grep -qo -- "--fix-bug") ;then
        fix_bug
      fi
      echo "$SIGNING_WITH_AOSPKEY"
      python $bin/tools/signapk/resign.py "$systemdir" "$bin/tools/signapk/AOSP_security" "$bin/$HOST/$platform/lib64"> $TARGETDIR/resign.log
      ./makeimg.sh "--ab${use_config}"
      exit 0
      ;;
    esac 
fi
