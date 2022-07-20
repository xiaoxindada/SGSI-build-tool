#!/sbin/sh
DEBUG=true
CLEAN=true

author="Xiaoxindada"
email="https://github.com/xiaoxindada"
HOME="/data/media/vbmeta_work"
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
  # disable offset is 123

  local backup=true
  export system="$HOME/system"
  [ -e $system/system ] && export system="$system/system"
  export vendor="$HOME/vendor"

  [ ! -f $HOME/system.prop ] && cp -f $system/build.prop $HOME/system.prop
  [ ! -f $HOME/vendor.prop ] && cp -f $vendor/build.prop $HOME/vendor.prop

  local partitions="vbmeta$slot vbmeta_system$slot vbmeta_vendor$slot"
  for partition in $partitions; do
    if [ -e /dev/block/by-name/$partition ]; then
      [ $DEBUG = true ] && ui_print "found $partition, start patching..."
      [ $backup = true ] && $BB dd if=/dev/block/by-name/$partition of=$HOME/${partition}_original.img
      $BB printf "\x03" | $BB dd of=/dev/block/by-name/$partition seek=123 bs=1 conv=notrunc # patch flags 3
    fi
  done
}

clean() {
  rm -rf $TMP $HOME
}

set_mount "system" "vendor"
patch_vbmeta
unset_mount "system" "vendor"

[ $CLEAN = true ] && clean
