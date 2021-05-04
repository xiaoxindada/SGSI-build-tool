#!/bin/bash

# Copyright (C) 2020 Xiaoxindada <2245062854@qq.com>

LOCALDIR=`cd "$( dirname $0 )" && pwd`
cd $LOCALDIR
source ./bin.sh

partition_name="system system_ext vendor product odm system_a system_ext_a vendor_a product_a odm_a system_b system_ext_b vendor_b product_b odm_b"

ab="false"
a_only="false"
virtual_ab="false"
ab_slot="false"

echo "支持的super.img类型有: a_only ab virtual_ab"

while true ;do
  read -p "清输入需要生成的类型: " super_type
  case $super_type in
    "a_only")
      a_only="true"
      break;;
    "ab")  
      ab="true"
      ab_slot="true"
      break;;
    "virtual_ab")
      ab="true"
      virtual_ab="true"
      ab_slot="true"
      break;;
      *) 
      echo "输入错误！清重试"
      ;;
  esac
done

for partition in $partition_name ;do
  if [ -e $partition.img ];then
    mv $partition.img $bin/build_super
  fi
done

cd $bin/build_super
cat ./misc_into.txt > ./build_super.txt

if [ $a_only = "true" ];then
  cat ./a_only.txt >> ./build_super.txt
fi

if [ $ab = "true" ];then
  cat ./ab.txt >> /build_super.txt
fi

if [ $virtual_ab = "true" ];then
  cat ./virtual_ab.txt >> ./build_super.txt
fi

if [ $ab_slot = "true" ];then
  cat ./ab_slot.txt >> ./build_super.txt
fi

printf "当前支持打包的分区为:\n"
echo -e "\033[33m${partition_name}\033[0m" | tr '\n' ' '

partition_list=$(ls | grep ".img$" | sed 's/\.img//g' | tr '\n' ' ')
printf "\n\n当前存在的分区为:\n"
echo -e "\033[33m${partition_list}\033[0m"

read -p "请输入你要打包的分区 (多个分区记得留空格): " partition

for i in $partition ;do
  if [ ! -e ./$i.img ];then
    echo "$i.img不存在！"
    mv ./*.img $LOCALDIR
    exit
  fi
  
  filesystem_info() {
    file $i.img &> filesystem_info.txt
    cat filesystem_info.txt | grep -qo "sparse"
  }
  if filesystem_info ;then
    rm -rf filesystem_info.txt
    echo "$i.img不为rmg!"
    exit
  else
    rm -rf filesystem_info.txt
  fi
done

mkdir -p ./sum
for i in $partition ;do
  mv $i.img ./sum
done
base_size=$(du -sb ./sum | awk '{print $1}')
if [ "$base_size" -le "1073741824" ];then
  printf "\n当前img大小总和为:\n==================\n$(du -sb ./sum | awk '{print $1}') (小于1G请使用1G打包)\n==================\n\n"
else
  printf "\n当前img大小总和为:\n==================\n$(du -sh ./sum | awk '{print $1}') (取整数打包)\n==================\n\n"
fi
mv ./sum/* ./
rm -rf ./sum

echo -e "\033[33m 开始打包
super分区大小为要打包的rimg的总大小
super最终实际可用大小等于要打包的rimg的总大小
打包数据用G为单位时候要为整数
如果打包数据不为整数时用M为单位
用B为单位打包时无需带单位
\033[0m"
 
read -p "请输入super分区大小: " supersize

superM="$(echo "$supersize" | sed 's/M//g')"
superG="$(echo "$supersize" | sed 's/G//g')"

if [ $(echo "$supersize" | grep 'M') ];then
  superssize="$(($superM*1024*1024))"
elif [ $(echo "$supersize" | grep 'G') ];then
  superssize="$(($superG*1024*1024*1024))"
else
  superssize="$supersize"
fi

read -p "请输入super最终实际可用大小: " size

sizeM="$(echo "$size" | sed 's/M//g')"
sizeG="$(echo "$size" | sed 's/G//g')"

if [ $(echo "$size" | grep 'M') ];then
  ssize="$(($sizeM*1024*1024))"
elif [ $(echo "$size" | grep 'G') ];then
  ssize="$(($sizeG*1024*1024*1024))"
else
  ssize="$size"
fi

echo "dynamic_partition_list=$partition
super_main_partition_list=$partition
super_super_device_size=$superssize
super_main_group_size=$ssize
" >> ./build_super.txt
echo "super.img生成信息整合完毕,正在生成super.img..."
python ./build_super_image.py ./build_super.txt ./super.img
if [ $? != "0" ];then
  echo "打包失败 错误日至如上"
else
  echo "super.img已生成，已输出至super目录"
fi

rm -rf ./build_super.txt
   
cd $LOCALDIR
rm -rf ./super
mkdir ./super
mv $bin/build_super/*.img ./
mv ./super.img ./super/
chmod 777 -R ./super
