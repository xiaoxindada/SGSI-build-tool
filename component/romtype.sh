#!/bin/bash
 
LOCALDIR=`cd "$( dirname ${BASH_SOURCE[0]} )" && pwd`
cd $LOCALDIR
source $LOCALDIR/../bin.sh
source $LOCALDIR/../language_helper.sh

os_type="$1"
systemdir="$TARGETDIR/system/system"
configdir="$TARGETDIR/config"
rom_folder="$LOCALDIR/rom_make_patch/$(echo $os_type | tr "[:upper:]" "[:lower:]")"
vintf_folder="$LOCALDIR/add_etc_vintf_patch/$(echo $os_type | tr "[:upper:]" "[:lower:]")"
debloat_foldir="$LOCALDIR/../apps_clean"
debloat_script="$(echo $os_type | tr "[:upper:]" "[:lower:]").sh"

# add libs
add_libs() {
  local lib_dirs="lib lib64"

  # add libs
  cp -frpn $rom_folder/add_libs/system/* $systemdir
      
  # add libs fs data
  rm -rf $TARGETDIR/add_libs_fs
  mkdir -p $TARGETDIR/add_libs_fs
  
  if [ -f $configdir/system_fs_config ];then
    for lib_arch in $lib_dirs ;do
      [[ ! -d $rom_folder/add_libs/system/$lib_arch ]] || [[ $(cd $rom_folder/add_libs/system/$lib_arch; ls | wc -l; cd $LOCALDIR) = 0 ]] && continue
      for libs in $(ls $rom_folder/add_libs/system/$lib_arch) ;do
        echo "system/system/$lib_arch/$libs 0 0 0644" >> $TARGETDIR/add_libs_fs/${os_type}_add_libs_fs
      done
    done
    cat $TARGETDIR/add_libs_fs/${os_type}_add_libs_fs >> $configdir/system_fs_config
  fi
    
  if [ -f $configdir/system_file_contexts ];then
    for lib_arch in $lib_dirs ;do
       [[ ! -d $rom_folder/add_libs/system/$lib_arch ]] || [[ $(cd $rom_folder/add_libs/system/$lib_arch; ls | wc -l; cd $LOCALDIR) = 0 ]] && continue
      for libs in $(ls $rom_folder/add_libs/system/$lib_arch) ;do
        echo "/system/system/$lib_arch/$(echo $libs | sed -e 's|\.|\\.|g') u:object_r:system_lib_file:s0" >> $TARGETDIR/add_libs_fs/${os_type}_add_libs_contexts
      done
    done
    cat $TARGETDIR/add_libs_fs/${os_type}_add_libs_contexts >> $configdir/system_file_contexts
  fi
}
if [ -d $rom_folder/add_libs/system ];then
  add_libs
fi

# pixel
if [ $os_type = "Pixel" ];then
  echo "$OS_TYPE_CHECK_STR: $os_type"
  # Add oem properites
  #./add_build.sh
  $vintf_folder/add_vintf.sh
  # Fixing ROM Features
  $rom_folder/make.sh
  echo "$DEBLOATING_STR"
  $debloat_foldir/$debloat_script "$systemdir"
  # Not flatten apex
  echo "true" > $TARGETDIR/apex_state
fi
