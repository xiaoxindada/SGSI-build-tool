#!/bin/bash

# Copyright (C) 2021 Xiaoxindada <2245062854@qq.com>

LOCALDIR=`cd "$( dirname ${BASH_SOURCE[0]} )" && pwd`
cd $LOCALDIR
source ./bin.sh
source ./language_helper.sh

Usage() {
cat <<EOT
Usage:
$0 sparse image path
EOT
}

if [ "$1" = "" ];then
  Usage
  exit
fi

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
        echo "$imagedir/$image $SIMG2IMG_SKIP"
        continue
      fi
      image_files=$(ls $imagedir | grep "$image")
      old_name=$(echo ${image_files%%.*})
      new_name=$(echo "$old_name" | sed 's/$/&r/')
      simg_file="$image_files"
      rimg_file="${new_name}.img"

      echo "$imagedir/$simg_file $CONVERTING_RAW_IMAGE"
      $bin/simg2img "$imagedir/$simg_file" "$imagedir/$rimg_file"
      if [ $? != "0" ];then
        echo "$imagedir/$simg_file $CONVERTFAIL"
        return 1
      fi
      mv -f "$imagedir/$rimg_file" "$imagedir/$simg_file" # Rename raw image to sparse image name
    fi
  done
}
main
rm -rf $imagedir/image_list.txt
