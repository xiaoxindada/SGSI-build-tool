#!/bin/bash

# Copyright (C) 2020 Xiaoxindada <2245062854@qq.com>

LOCALDIR=`cd "$( dirname $0 )" && pwd`
cd $LOCALDIR
source ./bin.sh

Usage() {
cat <<EOT
Usage:
$0 <Build Type> <OS Type> <Firmware Path> [Other args]
  Build Type: [--AB|--ab] or [-A|-a|--a-only]
  OS Type: Rom OS type to build
  Firmware Path: Rom Firmware Path

  Other args:
    [--fix-bug]: Fix bugs in Rom
EOT
}

case $1 in 
  "--AB"|"--ab")
    build_type="--ab"
    ;;
  "-A"|"-a"|"--a-only")
    build_type="-a"
    echo "暂不支持A-only"
    exit
    ;;
  "-h"|"--help")
    Usage
    exit
    ;;    
  *)
    Usage
    exit
    ;;
esac

if [ $# -lt 3 ];then
  Usage
  exit
fi

os_type="$2"
firmware="$3"
build_type="$build_type"
other_args=""
shift 3

if ! (cat ./make/rom_support_list.txt | grep -qo "$os_type");then
  echo "此rom未支持!"
  echo "支持的rom有:"
  cat ./make/rom_support_list.txt
  exit
fi

if [ ! -e $firmware ];then
  if [ ! -e ./tmp/$firmware ];then
    echo "当前固件不存在"
    exit
  fi  
fi

function firmware_extract() {
  partition_list="system vendor system_ext odm product reserve boot vendor_boot"
  
  if [[ -e $firmware || -e ./tmp/$firmware ]];then
    if [ -e $firmware ];then
      7z x -y "$firmware" -o"./tmp/"
    fi  
    if [ -e ./tmp/$firmware ];then
      7z x -y "./tmp/$firmware" -o"./tmp/"
    fi
  else
    echo "当前固件不存在！"
    exit 
  fi

  for i in $(ls ./tmp);do
    [ ! -d ./tmp/$i ] && continue
    cd ./tmp/$i
    if [ $(ls | wc -l) != "0" ];then
      mv -f ./* ../
    fi
    cd $LOCALDIR
  done

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
}

echo "环境初始化中 请稍候..."
chmod -R 777 ./
rm -rf ./*.img
./workspace_cleanup.sh > /dev/null 2>&1
echo "初始化环境完成"

if [[ "$1" = "--fix-bug" ]];then
  other_args+="--fix-bug"
  shift
fi

firmware_extract
if [ -e ./system.img ];then
  echo "./SGSI.sh $build_type $os_type $other_args"
  ./SGSI.sh $build_type $os_type $other_args
  ./workspace_cleanup.sh
  exit
else
  echo "未检测到system.img, 无法制作SGSI！"
  exit
fi
