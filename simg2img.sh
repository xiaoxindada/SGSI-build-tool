#!/bin/bash

# Copyright (C) 2021 Xiaoxindada <2245062854@qq.com>

LOCALDIR=`cd "$( dirname $0 )" && pwd`
cd $LOCALDIR
source ./bin.sh

imagedir="$1" 

echo "system.img
system_ext.img
vendor.img
product.img
odm.img" > $imagedir/image_list.txt

main() {
  for image in $(cat $imagedir/image_list.txt) ;do
    if [ -e $imagedir/$image ];then
      if ! (echo `file $imagedir/$image` | grep -qo "sparse") ;then
        echo "$imagedir/$image 不是simg, 正在跳过转换rimg"
        continue
      fi
      image_files=$(ls $imagedir | grep "$image")
      old_name=$(echo ${image_files%%.*})
      new_name=$(echo "$old_name" | sed 's/$/&r/')
      simg_file="$image_files"
      rimg_file="${new_name}.img"

      echo "$imagedir/$simg_file 转rimg中"
      $bin/simg2img "$imagedir/$simg_file" "$imagedir/$rimg_file"
      if [ $? != "0" ];then
        echo "$imagedir/$simg_file 转换失败"
        return 1
      fi
      mv -f "$imagedir/$rimg_file" "$imagedir/$simg_file" # raw image 重命名回 sparse image文件名
    fi
  done
}
main
rm -rf $imagedir/image_list.txt
