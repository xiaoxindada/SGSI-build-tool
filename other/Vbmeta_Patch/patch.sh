#!/sbin/sh
DEBUG=true
CLEAN=true

author="Xiaoxindada"
email="https://github.com/xiaoxindada"
HOME="/data/vbmeta_work"
TMP="/tmp"
TOOLSDIR="$HOME/tools"
BB="$TOOLSDIR/busybox"
MAGISTBOOT="$TOOLSDIR/magiskboot"
. $TOOLSDIR/util_functions.sh

OUTFD=$1
ui_print() {
  echo -e "ui_print $1\nui_print" >/proc/self/fd/$OUTFD
}

ui_print "vbmeta patch by $author at $email"

cd $HOME
get_slot

set_mount() {
  local block="$*"

  ui_print "set mount"
  for b in $block; do
    mkdir -p $b
    if [ -e /dev/block/by-name/$b$slot ]; then
      $BB blockdev --setrw /dev/block/by-name/$b$slot
      $BB mount -t auto -o rw,loop /dev/block/by-name/$b$slot $b || $BB mount -t auto -o ro,loop /dev/block/by-name/$b$slot $b
    elif [ -e /dev/block/mapper/$b$slot ]; then
      $BB blockdev --setrw /dev/block/mapper/$b$slot
      $BB mount -t auto -o rw,loop /dev/block/mapper/$b$slot $b || $BB mount -t auto -o /dev/block/mapper/$b$slot $b
    else
      abort "device partition unsupported!"
    fi
  done
}

unset_mount() {
  local mount_dir="$*"

  for d in $mount_dir; do
    $BB umount $d
  done
}

patch_vbmeta() {
  # see https://cs.android.com/android/platform/superproject/+/master:system/core/fastboot/fastboot.cpp;l=972;drc=master
  # https://cs.android.com/android/platform/superproject/+/master:system/core/fastboot/fastboot.cpp;l=975;drc=master
  # disable offset is 120
  # Common flags 3 for new devices from
  # https://github.com/LineageOS/android_device_xiaomi_sm8250-common/blob/lineage-18.1/BoardConfigCommon.mk#L237

  local backup=true
  local original_hex="00000000000000006176"
  local patch_flags2_hex="0000000200000006176" # flags 2
  local patch_flags3_hex="0000000300000006176" # flags 3
  export system="$HOME/system"
  [ -e $system/system ] && export system="$system/system"
  export vendor="$HOME/vendor"

  [ ! -f $HOME/system.prop ] && cp -f $system/build.prop $HOME/system.prop
  [ ! -f $HOME/vendor.prop ] && cp -f $vendor/build.prop $HOME/vendor.prop

  if [ -e /dev/block/by-name/vbmeta$slot ]; then
    [ $DEBUG = true ] && ui_print "found vbmeta partition, start patching..."
    $BB dd if=/dev/block/by-name/vbmeta$slot of=$HOME/vbmeta_original.img
    if $BB cat $HOME/vendor.prop | $BB grep -qo "ro.boot.dynamic_partitions=true"; then
      $BB xxd -p -c "256" $HOME/vbmeta_original.img | $BB sed "s/$original_hex/$patch_flags3_hex/" | xxd -p -r >$HOME/vbmeta_patch.img
      [ $? = 0 ] && ui_print "patch vbmeta flags 3 success!"
    else
      $BB xxd -p -c "256" $HOME/vbmeta_original.img | $BB sed "s/$original_hex/$patch_flags2_hex/" | xxd -p -r >$HOME/vbmeta_patch.img
      [ $? = 0 ] && ui_print "patch vbmeta flags 2 success!"
    fi
    $BB dd if=$HOME/vbmeta_patch.img of=/dev/block/by-name/vbmeta$slot conv=notrunc
  fi
}

set_mount "system" "vendor"
patch_vbmeta
unset_mount "system" "vendor"

[ $CLEAN = true ] && clean
