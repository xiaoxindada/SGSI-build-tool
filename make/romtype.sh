#!/bin/bash
 
LOCALDIR=`cd "$( dirname $0 )" && pwd`
cd $LOCALDIR

os_type="$1"
systemdir="$LOCALDIR/../out/system/system"

# pixel
if [ $os_type = "Pixel" ];then
  echo "检测当前为pixel原生系统"
  #echo "正在完善特性"
  #./add_build.sh
  #./add_etc_vintf_patch/pixel/add_vintf.sh
  # rom修补处理
  ./rom_make_patch/pixel/make.sh
  echo "正在精简推广"
  ../apps_clean/pixel.sh "$systemdir"
fi
 
