#!/bin/bash
 
LOCALDIR=`cd "$( dirname $0 )" && pwd`
cd $LOCALDIR
source ./bin.sh

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
    echo "正在提取$partition.img..."
    python3 $bin/imgextractor.py $IMAGESDIR/$partition.img $TARGETDIR
    if [ $? != "0" ];then
      echo "$partition.img提取失败"
      exit
    fi
  fi
done
