#!/bin/bash

LOCALDIR=`cd "$( dirname $0 )" && pwd`
cd $LOCALDIR
WORKSPACE=$LOCALDIR/../workspace
IMAGESDIR=$WORKSPACE/images
TARGETDIR=$WORKSPACE/out

systemdir="$TARGETDIR/system/system"
scirpt_name=$(echo ${0##*/})
src_dir=$LOCALDIR/$(echo ${scirpt_name%%.*}) 

echo "${scirpt_name%%.*} fixing..."

# 部分机型储存修复
if [ -d $systemdir/apex/com.google.android.mediaprovider ];then
  cp -frp $src_dir/system/apex/com.google.android.mediaprovider/* $systemdir/apex/com.google.android.mediaprovider/
fi

# 禁用media.c2
disable_media_c2() {
  local files=$(grep "android.hardware.media.c2" $systemdir -ril)
  for file in $files ;do
    if [ $(echo "$file" | grep ".xml$" ) ];then
      sed -i -e "s|<name>android.hardware.media.c2</name>|<name>android.hardware.media.c2.disable</name>|" $file
    fi
  done
}
disable_media_c2
