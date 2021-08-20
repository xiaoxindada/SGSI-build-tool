#!/bin/bash

# Copyright (C) 2021 Xiaoxindada <2245062854@qq.com>

LOCALDIR=`cd "$( dirname ${BASH_SOURCE[0]} )" && pwd`
cd $LOCALDIR
source ./bin.sh

dtbodir="$LOCALDIR/dtbo"

rm -rf $dtbodir/new_dtbo_files
rm -rf $dtbodir/new_dtbo_image
mkdir -p $dtbodir/new_dtbo_files
mkdir -p $dtbodir/new_dtbo_image
if [ -d $dtbodir/dtbo_files ];then
  mv $dtbodir/dtbo_files $dtbodir/dtbo_files_old
fi

dts_files_name=$(ls $dtbodir/dts_files)
for dts_files in $dts_files_name ;do
  new_dtbo_files=$(echo "$dts_files" | sed 's/dts/dtbo/g')
  echo "正在回编译$dts_files为$new_dtbo_files"
  $bin/dtc -I "dts" -O "dtb" "$dtbodir/dts_files/$dts_files" -a "4" -o "$dtbodir/new_dtbo_files/$new_dtbo_files"  > /dev/null 2>&1
done

file_number=$(ls -l $dtbodir/new_dtbo_files | grep "^-" | wc -l)
echo "当前dtbo文件个数为：$file_number "

repackage_dtbo_image() {
  echo "正在生成makedtboimg.sh打包脚本..."
  rm -rf $dtbodir/makedtboimg.sh
  touch $dtbodir/makedtboimg.sh && chmod 777 $dtbodir/makedtboimg.sh
  echo "#!/bin/bash" >> $dtbodir/makedtboimg.sh
  echo "$bin/mkdtimg create $dtbodir/new_dtbo_image/dtbo.img \\" >> $dtbodir/makedtboimg.sh
  echo "$dtbodir/new_dtbo_files/dtbo.0 \\" >> $dtbodir/makedtboimg.sh
  a="1"
  b="$file_number"
  c=$(($b-1))
  while [ $a -le $b ];do
    echo "$dtbodir/new_dtbo_files/dtbo.${a} \\" >> $dtbodir/makedtboimg.sh
    let a++
  done
  sed -i "/dtbo.${b}/d" $dtbodir/makedtboimg.sh
  sed -i "/dtbo.${c}/d" $dtbodir/makedtboimg.sh
  echo "$dtbodir/new_dtbo_files/dtbo.${c}" >> $dtbodir/makedtboimg.sh
  echo "正在生成dtbo.img..."
  $dtbodir/makedtboimg.sh
}
repackage_dtbo_image
echo "dtbo.img已生成至$dtbodir/new_dtbo_image文件夹中"
chmod 777 -R $dtbodir
