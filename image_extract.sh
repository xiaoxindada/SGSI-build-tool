#!/bin/bash
 
LOCALDIR=`cd "$( dirname $0 )" && pwd`
cd $LOCALDIR
source ./bin.sh

systemdir="./out/system/system"
partition_name="
system
vendor
product
system_ext
"
rm -rf ./out
mkdir ./out

for partition in $partition_name ;do
  if [[ -e $LOCALDIR/$partition.img ]];then
    echo "正在提取$partition.img..."
    python3 $bin/imgextractor.py $partition.img ./out
    if [ $? != "0" ];then
      echo "$partition.img提取失败"
      exit
    fi
  fi
done
