#!/bin/bash
 
LOCALDIR=`cd "$( dirname ${BASH_SOURCE[0]} )" && pwd`
cd $LOCALDIR
source ./bin.sh
source ./language_helper.sh
EROFS_MAGIC_V1="e2e1f5e0" # 0xE0F5E1E2
EXT_MAGIC="53ef" # 0xEF53
SQUASHFS_MAGIC="68737173" # 0x73717368
EXT_OFFSET="1080"
EROFS_OFFSET="1024"
SQUASHFS_OFFSET="0"


partitions="system vendor product system_ext"

rm -rf $TARGETDIR
mkdir -p $TARGETDIR

for partition in $partitions ;do
  if [[ -e $IMAGESDIR/${partition}.img ]];then
    if [ $(xxd -p -l "2" --skip "$EXT_OFFSET" "$IMAGESDIR/${partition}.img") = "$EXT_MAGIC" ];then
      echo "$DETECTED_EXT_FILESYSTEM_IMAGE"
      echo "${partition}.img $EXTRACTING_STR"
      python3 $bin/imgextractor.py "$IMAGESDIR/${partition}.img" "$TARGETDIR"
      [ $? != 0 ] && echo "${partition}.img $FAILEXTRACT_STR" && exit 1
    elif [ $(xxd -p -l "4" --skip "$EROFS_OFFSET" "$IMAGESDIR/${partition}.img") = "$EROFS_MAGIC_V1" ];then
      echo "$DETECTED_EROFS_FILESYSTEM_IMAGE"
      echo "${partition}.img $EXTRACTING_STR"
      $bin/erofsUnpackKt "$IMAGESDIR/${partition}.img" "$TARGETDIR"
      [ $? != 0 ] && echo "${partition}.img $FAILEXTRACT_STR" && exit 1
    elif [ $(xxd -p -l "4" --skip "$SQUASHFS_OFFSET" "$IMAGESDIR/${partition}.img") = "$SQUASHFS_MAGIC" ];then
      echo "$DETECTED_SQUASHFS_FILESYSTEM_IMAGE"
      rm -rf "$TARGETDIR/$partition"
      unsquashfs -q -n -u -d "$TARGETDIR/$partition" "$IMAGESDIR/${partition}.img"
      [ $? != 0 ] && echo "${partition}.img $FAILEXTRACT_STR" && exit 1
    else
      echo "$partition $IMAGE_UNSUPPORT_EXTRACT"
      exit 1
    fi
    continue
  fi
done
