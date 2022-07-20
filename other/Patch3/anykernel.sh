# AnyKernel3 Ramdisk Mod Script
# osm0sis @ xda-developers

## AnyKernel setup
# begin properties
properties() { '
kernel.string= xiaoxinSGSI patchs
do.devicecheck=0
do.modules=0
do.systemless=1
do.cleanup=0
do.cleanuponabort=0
device.name1=
device.name2=
device.name3=
device.name4=
device.name5=
supported.versions=
supported.patchlevels=
'; } # end properties

# shell variables
block=boot;
is_slot_device=auto;
ramdisk_compression=auto;

rm -rf $AKHOME

# import patching functions/variables - see for reference
. tools/ak3-core.sh;

ui_print "workspace is: $home"
ui_print "current partition: $block$slot";

# ui_print current selinux status
selinux_status() {
  local status;
  status=$(grep -qo "androidboot.selinux=permissive" $1);
  if $status; then
    ui_print "selinux status is: permissive";
  else
    ui_print "selinux status is: force";
  fi;
}
selinux_status /proc/cmdline;

## AnyKernel install
dump_boot;

# copy ramdisk_patch files to new ramdisk
if [ "$(ls $home/ramdisk_patch)" ];then
  # set permissions and lable for ramdisk_patch files
  cd $home/ramdisk_patch;
  chmod 750 init*;
  chcon "u:object_r:rootfs:s0" init*;
  [ -f init ] && chcon "u:object_r:init_exec:s0" init;  
  cd $home
  ui_print "copy ramdisk_patch...";
  cp -f $home/ramdisk_patch/* $home/ramdisk/;
fi;
 
# use boot permissive
patch_cmdline "androidboot.selinux" "androidboot.selinux=permissive";

write_boot;
## end install

# prop changes
[ -f /vendor/build.prop ] && ui_print "patching /vendor/build.prop...";
backup_file /vendor/build.prop

# Disable privapp_permissions
patch_prop /vendor/build.prop "ro.control_privapp_permissions" "disable";

# Force apex not updatable
#patch_prop /vendor/build.prop "ro.apex.updatable" "false";
