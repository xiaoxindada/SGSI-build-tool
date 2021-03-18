#!/bin/bash

# Copyright (C) 2020 Xiaoxindada <2245062854@qq.com>

LOCALDIR=`cd "$( dirname $0 )" && pwd`
cd $LOCALDIR

source ./bin.sh

Usage() {
cat <<EOT
Usage:
$0 AB|ab or $0 A|a
EOT
}

case $1 in 
  "AB"|"ab")
    echo "" > /dev/null 2>&1
    ;;
  "A"|"a")
    echo "暂不支持A-only"
    exit
    ;;  
  *)
    Usage
    exit
    ;;
esac

echo "环境初始化中 请稍候..."
chmod -R 777 ./
rm -rf ./*.img
./workspace_cleanup.sh > /dev/null 2>&1
echo "初始化环境完成"
read -p "请输入需要解压的zip: " zip
echo "解压刷机包中..."

if [ -e $zip ] || [ -e ./tmp/$zip ];then
  if [ -e ./tmp/$zip ];then
    7z x -y "./tmp/$zip" -o"./tmp/"
    for i in $(ls ./tmp);do
      [ ! -d ./tmp/$i ] && continue
      cd ./tmp/$i
      mv -f ./* ../
      cd $LOCALDIR
    done
  else 
    7z x -y "$zip" -o"./tmp/"
    for i in $(ls ./tmp);do
      [ ! -d ./tmp/$i ] && continue
      cd ./tmp/$i
      mv -f ./* ../
      cd $LOCALDIR
    done    
  fi
  echo "解压zip完成"
else
  echo "当前zip不存在！"
  echo $zip
  exit 
fi

partition_list="system vendor system_ext odm product reserve"

cd $LOCALDIR/tmp
for partition in $partition_list ;do
  # payload.bin检测
  if [ -e ./payload.bin ];then
    mv ./payload.bin ../payload/
    cd ../payload
    echo "解压payload.bin中..."
    python ./payload.py ./payload.bin ./out
    for i in $partition_list ;do
      if [ -e ./out/$i.img ];then
        echo "移动$i.img至工具目录..."
        mv ./out/$i.img ../
      fi
    done
    rm -rf ./payload.bin
    rm -rf ./out/*
    cd $LOCALDIR/tmp
  fi

  # dat.br检测
  if [ -e ./${partition}.new.dat.br ];then
    echo "正在解压${partition}.new.dat.br"
    $bin/brotli -d ${partition}.new.dat.br
    python $bin/sdat2img.py ${partition}.transfer.list ${partition}.new.dat ./${partition}.img
    mv ./${partition}.img ../
    rm -rf ./${partition}.new.dat
  fi
  
  # 分段dat检测
  if [ -e ./${partition}.new.dat.1 ];then
    echo "检测到分段${partition}.new.dat，正在合并"
    cat ./${partition}.new.dat.{1..999} 2>/dev/null >> ./${partition}.new.dat
    rm -rf ./${partition}.new.dat.{1..999}
    python $bin/sdat2img.py ${partition}.transfer.list ${partition}.new.dat ./${partition}.img
    mv ./${partition}.img ../
    rm -rf ./${partition}.new.dat
  fi

  # dat检测
  if [ -e ./${partition}.new.dat ];then
    echo "正在解压${partition}.new.dat"
    python $bin/sdat2img.py ${partition}.transfer.list ${partition}.new.dat ./${partition}.img
    mv ./${partition}.img ../
  fi

  #img检测
  if [ -e ./${partition}.img ];then
    mv ./${partition}.img ../
  fi
done
cd $LOCALDIR

make_type=$1
if [ -e ./system.img ];then
  case $make_type in
    "A"|"a") 
      echo "暂不支持"
      exit
      ;;
    "AB"|"ab")
      ./SGSI.sh "AB"
      ./workspace_cleanup.sh
      exit
      ;;
    esac
else
  echo "未检测到system.img, 无法制作SGSI！"
  exit
fi
