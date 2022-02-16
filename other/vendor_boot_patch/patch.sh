#!/sbin/sh
DEBUG=true
CLEAN=true

author="Xiaoxindada"
email="https://github.com/xiaoxindada"
HOME="/data/vendor_boot_work"
TMP="/tmp"
TOOLSDIR="$HOME/tools"
BB="$TOOLSDIR/busybox"
MAGISTBOOT="$TOOLSDIR/magiskboot"
. $TOOLSDIR/util_functions.sh

OUTFD=$1
ui_print() {
  echo -e "ui_print $1\nui_print" >/proc/self/fd/$OUTFD
}

ui_print "vendor_boot patch by $author at $email"

cd $HOME
get_slot

set_mount() {
  local block="$*"

  ui_print "set mount"
  for b in $block; do
    mkdir -p $b
    if [ -e /dev/block/by-name/$b$slot ]; then
      $BB blockdev --setrw /dev/block/by-name/$b$slot
      $BB mount -t auto -o rw,loop /dev/block/by-name/$b$slot $b || mount -t auto -o ro,loop /dev/block/by-name/$b$slot $b
    elif [ -e /dev/block/mapper/$b$slot ]; then
      $BB blockdev --setrw /dev/block/mapper/$b$slot
      $BB mount -t auto -o rw,loop /dev/block/mapper/$b$slot $b || mount -t auto -o /dev/block/mapper/$b$slot $b
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

patch_vendor_boot() {
  local backup=true
  export system="$HOME/system"
  [ -e $system/system ] && export system="$system/system"
  export vendor="$HOME/vendor"

  [ ! -f $HOME/system.prop ] && cp -f $system/build.prop $HOME/system.prop
  [ ! -f $HOME/vendor.prop ] && cp -f $vendor/build.prop $HOME/vendor.prop

  rm -rf $HOME/out
  mkdir -p $HOME/out

  enable_permissive() {
    local header="$HOME/out/header"
    local search_cmdline_index=$($BB grep -n "^cmdline=" $header | $BB cut -d ":" -f 1)

    [ ! -f $header ] && abort "header file not found!"
    cp -f $header header.bak
    $BB sed -i "s/androidboot.selinux=enforcing/androidboot.selinux=permissive/" $header
    $BB sed -i "s/androidboot.selinux=permissive//g" $header
    $BB sed -i "/^cmdline=/{s/$/& androidboot.selinux=permissive/}" $header # match append
    $BB sed -i -e 's;  *; ;g' -e 's;[ \t]*$;;' $header
  }

  if [ -e /dev/block/by-name/vendor_boot$slot ]; then
    ui_print "Found vendor_boot$slot partition"
    $BB dd if=/dev/block/by-name/vendor_boot$slot of=$HOME/vendor_boot.img
    cp -f $HOME/vendor_boot.img $HOME/out/vendor_boot.img
    cd $HOME/out
    $MAGISTBOOT unpack -h vendor_boot.img
    enable_permissive
    $MAGISTBOOT repack vendor_boot.img
    [ ! -f new-boot.img ] && abort "repack vendor_boot.img failed!"
    mv -f new-boot.img $HOME/vendor_boot_new.img
    cd $HOME
    $BB dd if=$HOME/vendor_boot_new.img of=/dev/block/by-name/vendor_boot$slot conv=notrunc
  fi
}

clean() {
  rm -rf $TMP $HOME
}

set_mount "system" "vendor"
patch_vendor_boot
unset_mount "system" "vendor"

[ $CLEAN = true ] && clean
