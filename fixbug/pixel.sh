#!/bin/bash

LOCALDIR=`cd "$( dirname ${BASH_SOURCE[0]} )" && pwd`
cd $LOCALDIR
source $LOCALDIR/../language_helper.sh

WORKSPACE=$LOCALDIR/../workspace
IMAGESDIR=$WORKSPACE/images
TARGETDIR=$WORKSPACE/out

systemdir="$TARGETDIR/system/system"
scirpt_name=$(echo ${0##*/})
src_dir=$LOCALDIR/$(echo ${scirpt_name%%.*}) 

echo "${scirpt_name%%.*} fixing"

# Fix Media Provider
if [ $(cat $systemdir/build.prop | grep "ro.build.version.sdk" | head -n 1 | cut -d "=" -f 2) = "31" ];then
  if [ -d $systemdir/apex/com.google.android.mediaprovider ];then
    cp -frp $src_dir/system/apex/com.google.android.mediaprovider/* $systemdir/apex/com.google.android.mediaprovider/
  fi
fi

# Disable media.c2
disable_media_c2() {
  local files=$(grep "android.hardware.media.c2" $systemdir -ril)
  for file in $files ;do
    if [ $(echo "$file" | grep ".xml$" ) ];then
      sed -i -e "s|<name>android.hardware.media.c2</name>|<name>android.hardware.media.c2.disable</name>|" $file
    fi
  done
}
disable_media_c2
