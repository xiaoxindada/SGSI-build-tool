#!/bin/bash

# Copyright (C) 2020 Xiaoxindada <2245062854@qq.com>

LOCALDIR=`cd "$( dirname $0 )" && pwd`
cd $LOCALDIR
source ./bin.sh


partition_name="
system 
system_ext 
vendor 
product 
odm 
system_a 
system_ext_a 
vendor_a 
product_a 
odm_a
system_b 
system_ext_b 
vendor_b 
product_b
odm_b
"
ab_slot="false"

read -p "是否制造AB分区的super.img?(y/n): " AB
case $AB in
  "y"|"Y")
    echo "制造适用于ab分区的super.img时，先把要打包的img重命名为: 分区名称_a/b.img，且注意打包的分区输入时需要带_a/b"
    ab_slot="true"
    ;;
  "n"|"N")
    echo "否"  
    ;;
  *)
    echo "error!"
    exit
    ;;  
esac

for partition in $partition_name ;do
  if [ -e $partition.img ];then
    mv $partition.img $bin/build_super
  fi
done

cd $bin/build_super
cat ./misc_into.txt > ./build_super.txt
if [ $ab_slot = "true" ];then
  cat ./ab_slot.txt >> ./build_super.txt
fi

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
请确保要打包的所有img在工具根目录下且为rimg (必须遵守)
当前支持打包super.img的分区(ab 分区): system_a system_b system_ext_a system_ext_b vendor_a vendor_b product_a product_b odm_a odm_b
当前支持打包super.img的分区(a_only 分区): system system_ext vendor product odm
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
python3 ./build_super_image.py ./build_super.txt ./super.img
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
