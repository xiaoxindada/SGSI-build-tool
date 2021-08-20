#!/bin/bash

# Copyright (C) 2021 Xiaoxindada <2245062854@qq.com>
#		2021 Jiuyu <2652609017@qq.com>

LOCALDIR=`cd "$( dirname ${BASH_SOURCE[0]} )" && pwd`
cd $LOCALDIR
source ./bin.sh
source ./language_helper.sh

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
    echo $NOTSUPPAONLY
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

if ! (cat $LOCALDIR/make/rom_support_list.txt | grep -qo "$os_type");then
  echo $UNSUPPORTED_ROM
  echo $SUPPORTED_ROM_LIST
  cat $LOCALDIR/make/rom_support_list.txt
  exit 1
fi

if [ ! -e $firmware ];then
  if [ ! -e $LOCALDIR/tmp/$firmware ];then
    echo $NOTFOUNDFW
    exit 1
  fi  
fi

function firmware_extract() {
  partition_list="system vendor system_ext odm product reserve boot vendor_boot"
  
  if [ -e $firmware ];then
    7z x -y "$firmware" -o"./tmp/"
  fi
  if [ -e $LOCALDIR/tmp/$firmware ];then
    7z x -y "$LOCALDIR/tmp/$firmware" -o"$LOCALDIR/tmp/"
  fi

  for i in $(ls $LOCALDIR/tmp);do
    [ ! -d $LOCALDIR/tmp/$i ] && continue
    cd $LOCALDIR/tmp/$i
    if [ $(ls | wc -l) != "0" ];then
      mv -f ./* ../
    fi
    cd $LOCALDIR
  done

  cd $LOCALDIR/tmp
  for partition in $partition_list ;do
    # Detect payload.bin
    if [ -e ./payload.bin ];then
      mv ./payload.bin ../payload/
      cd ../payload
      echo $UNZIPINGPLB
      python ./payload.py ./payload.bin ./out
      for i in $partition_list ;do
        if [ -e ./out/$i.img ];then
          echo $MOVINGIMG
          mv ./out/$i.img $IMAGESDIR/
        fi
      done
      rm -rf ./payload.bin
      rm -rf ./out/*
      cd $LOCALDIR/tmp
    fi

    # Detect dat.br
    if [ -e ./${partition}.new.dat.br ];then
      echo "$UNPACKING_STR ${partition}.new.dat.br"
      $bin/brotli -d ${partition}.new.dat.br
      python $bin/sdat2img.py ${partition}.transfer.list ${partition}.new.dat ./${partition}.img
      mv ./${partition}.img $IMAGESDIR/
      rm -rf ./${partition}.new.dat
    fi
  
    # Detect split new.dat
    if [ -e ./${partition}.new.dat.1 ];then
      echo "$SPLIT_DETECTED ${partition}.new.dat, $MERGING_STR"
      cat ./${partition}.new.dat.{1..999} 2>/dev/null >> ./${partition}.new.dat
      rm -rf ./${partition}.new.dat.{1..999}
      python $bin/sdat2img.py ${partition}.transfer.list ${partition}.new.dat ./${partition}.img
      mv ./${partition}.img $IMAGESDIR/
      rm -rf ./${partition}.new.dat
    fi

    # Detect general new.dat
    if [ -e ./${partition}.new.dat ];then
      echo "$UNPACKING_STR ${partition}.new.dat"
      python $bin/sdat2img.py ${partition}.transfer.list ${partition}.new.dat ./${partition}.img
      mv ./${partition}.img $IMAGESDIR/
    fi

    # Detect image
    if [ -e ./${partition}.img ];then
      mv ./${partition}.img $IMAGESDIR/
    fi
  done

  cd $IMAGESDIR
}

echo $INITINGENV
chmod -R 777 ./
./workspace_cleanup.sh > /dev/null 2>&1
rm -rf $WORKSPACE
mkdir -p $IMAGESDIR
mkdir -p $TARGETDIR
echo $ENVINITFINISH

if [[ "$1" = "--fix-bug" ]];then
  other_args+="--fix-bug"
  shift
fi

firmware_extract
cd $LOCALDIR
if [ -e $IMAGESDIR/system.img ];then
  echo "./SGSI.sh $build_type $os_type $other_args"
  ./SGSI.sh $build_type $os_type $other_args
  ./workspace_cleanup.sh
  exit 0
else
  echo $NOTFOUNDSYSTEMIMG
  exit 1
fi
