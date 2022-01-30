#!/bin/bash
 
LOCALDIR=`cd "$( dirname ${BASH_SOURCE[0]} )" && pwd`
cd $LOCALDIR
source ./bin.sh
source ./language_helper.sh
EROFS_MAGIC_V1="e2e1f5e0" # 0xE0F5E1E2
EXT_MAGIC="53ef" # 0xEF53
EXT_OFFEST="1080"
EROFS_OFFEST="1024"
partitions="system vendor product system_ext"

rm -rf $TARGETDIR
mkdir -p $TARGETDIR

for partition in $partitions ;do
  if [[ -e $IMAGESDIR/${partition}.img ]];then
    if [ $(xxd -p -l "2" --skip "$EXT_OFFEST" "$IMAGESDIR/${partition}.img") = "$EXT_MAGIC" ];then
      echo "$DETECTED_EXT_FILESYSTEM_IMAGE"
      echo "${partition}.img $EXTRACTING_STR"
      python3 $bin/imgextractor.py "$IMAGESDIR/${partition}.img" "$TARGETDIR"
      [ $? != 0 ] && echo "${partition}.img $FAILEXTRACT_STR" && exit 1
    elif [ $(xxd -p -l "4" --skip "$EROFS_OFFEST" "$IMAGESDIR/${partition}.img") = "$EROFS_MAGIC_V1" ];then
      echo "$DETECTED_EROFS_FILESYSTEM_IMAGE"
      echo "${partition}.img $EXTRACTING_STR"
      $bin/erofsUnpackKt "$IMAGESDIR/${partition}.img" "$TARGETDIR"
      [ $? != 0 ] && echo "${partition}.img $FAILEXTRACT_STR" && exit 1
    fi
    continue
  fi
done
