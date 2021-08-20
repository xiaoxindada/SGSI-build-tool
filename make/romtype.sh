#!/bin/bash
 
LOCALDIR=`cd "$( dirname ${BASH_SOURCE[0]} )" && pwd`
cd $LOCALDIR
source $LOCALDIR/../bin.sh
source $LOCALDIR/../language_helper.sh


os_type="$1"
systemdir="$TARGETDIR/system/system"

# pixel
if [ $os_type = "Pixel" ];then
  echo "$PIXEL_DETECTED"
  #echo "Extending features"
  #./add_build.sh
  ./add_etc_vintf_patch/pixel/add_vintf.sh
  # Fixing ROM Features
  ./rom_make_patch/pixel/make.sh
  echo "$DEBLOATING_STR"
  ../apps_clean/pixel.sh "$systemdir"
fi
 
