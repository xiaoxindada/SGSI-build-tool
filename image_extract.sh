#!/bin/bash
 
LOCALDIR=`cd "$( dirname ${BASH_SOURCE[0]} )" && pwd`
cd $LOCALDIR
source ./bin.sh
source ./language_helper.sh

partition_name="
system
vendor
product
system_ext
"
rm -rf $TARGETDIR
mkdir -p $TARGETDIR

for partition in $partition_name ;do
  if [[ -e $IMAGESDIR/$partition.img ]];then
    echo "$EXTRACTING_STR $partition.img..."
    if ! python3 $bin/imgextractor.py $IMAGESDIR/$partition.img $TARGETDIR ;then
      echo -e "\033[33m $EXTRACTING_STR $EROFS_STR $partition.img... \033[0m"
      if ! $bin/erofsUnpackKt $IMAGESDIR/$partition.img $TARGETDIR ;then
        echo "$FAILEXTRACT_STR $partition.img"
        exit 1
      fi  
    fi
  fi
done
