#!/bin/bash

# Copyright (C) 2020 Xiaoxindada <2245062854@qq.com>

LOCALDIR=$(cd "$(dirname ${BASH_SOURCE[0]})" && pwd)
cd $LOCALDIR
source ./bin.sh
super_image="super_new.img"

rm -rf super/
mkdir -p super/

for image in $(ls | grep ".img$"); do
  image_name=$(echo $image | sed 's/\.img//g')
  image_non_slot_name=$(echo $image_name | sed -e 's/_a\b//' -e 's/_b\b//')
  mv -f ${image_name}.img $bin/build_super/${image_non_slot_name}.img
done

cd $bin/build_super/
./build_super_image.sh
if [ -s $super_image ]; then
  if ! (file $super_image | grep -qo "sparse"); then
    ./get_super_info.sh $super_image
    mv -f super_info.txt $LOCALDIR/super/
  fi
  mv -f $super_image $LOCALDIR/super/
  echo "Output: $LOCALDIR/super/$super_image"
else
  echo "$super_image 创建失败"
fi
mv -f *.img $LOCALDIR/
cd $LOCALDIR
exit 0
