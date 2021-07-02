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
  "AB"|"ab"|"A"|"a")
    echo "" > /dev/null 2>&1
    ;;
  *)
    Usage
    exit
    ;;
esac

echo "环境初始化中 请稍候..."
mkdir -p ./tmp
chmod -R 777 ./
chown -R root:root ./
rm -rf ./*.img
./workspace_cleanup.sh > /dev/null 2>&1
echo "初始化环境完成"
read -p "请输入需要解压的zip: " zip
echo "解压刷机包中..."

if [ -e $zip ] || [ -e ./tmp/$zip ];then
  if [ -e ./tmp/$zip ];then
    7z x "./tmp/$zip" -o"./tmp/"
  else 
    7z x "$zip" -o"./tmp/"
  fi
  echo "解压zip完成"
else
  echo "当前zip不存在！"
  exit 
fi

cd ./tmp
# payload.bin检测
if [ -e './payload.bin' ];then
  mv ./payload.bin ../payload
  echo "解压payload.bin中..."
  cd ../payload
  python2 ./payload.py ./payload.bin ./out
  mv ./payload.bin ../tmp
  echo "移动img至输出目录..."
  if [ -e "./out/product.img" ];then
    mv ./out/product.img ../tmp/
  fi
 
  if [ -e "./out/system_ext.img" ];then
    mv ./out/system_ext.img ../tmp/
  fi

  if [ -e "./out/reserve.img" ];then
    mv ./out/reserve.img ../tmp/
  fi

  if [ -e "./out/odm.img" ];then
    mv ./out/odm.img ../tmp/
  fi  
 
  if [ -e "./out/boot.img" ];then
    mv ./out/boot.img ../tmp/
  fi  
  
  if [ -e "./out/vendor_boot.img" ];then
    mv ./out/vendor_boot.img ../tmp/
  fi  
  mv ./out/system.img ../tmp/
  mv ./out/vendor.img ../tmp/
  rm -rf ./out/*
  cd ../tmp
  mv ./system.img ../
  mv ./vendor.img ../

  if [ -e "./product.img" ];then
    mv ./product.img ../
  fi

  if [ -e "./system_ext.img" ];then
    mv ./system_ext.img ../
  fi
 
  if [ -e "./reserve.img" ];then
    mv ./reserve.img ../
  fi
  
  if [ -e "./odm.img" ];then
    mv ./odm.img ../
  fi    

  if [ -e "./boot.img" ];then
    mv ./boot.img ../
  fi
  
  if [ -e "./vendor_boot.img" ];then
    mv ./vendor_boot.img ../
  fi  
  echo "转换完成"
fi

# br检测
if [ -e ./system.new.dat.br ];then
   echo "正在解压system.new.dat.br"
   $bin/brotli -d system.new.dat.br
   python $bin/sdat2img.py system.transfer.list system.new.dat ./system.img
   mv ./system.img ../
   rm -rf ./system.new.dat

  if [ -e ./vendor.new.dat.br ];then
    echo "正在解压vendor.new.br"
    $bin/brotli -d vendor.new.dat.br
    python $bin/sdat2img.py vendor.transfer.list vendor.new.dat ./vendor.img
    mv ./vendor.img ../
    rm -rf ./vendor.new.dat 
  fi

  if [ -e ./product.new.dat.br ];then
    echo "正在解压product.new.br"
    $bin/brotli -d product.new.dat.br
    python $bin/sdat2img.py product.transfer.list product.new.dat ./product.img
    mv ./product.img ../
    rm -rf ./product.new.dat
  fi

  if [ -e ./system_ext.new.dat.br ];then
    echo "正在解压system_ext.new.dat.br"
    $bin/brotli -d system_ext.new.dat.br
    python $bin/sdat2img.py system_ext.transfer.list system_ext.new.dat ./system_ext.img
    mv ./system_ext.img ../
    rm -rf ./system_ext.new.dat
  fi

  if [ -e ./odm.new.dat.br ];then
    echo "正在解压odm.new.dat.br"
    $bin/brotli -d odm.new.dat.br
    python $bin/sdat2img.py odm.transfer.list odm.new.dat ./odm.img
    mv ./odm.img ../
    rm -rf ./odm.new.dat
  fi
fi

# dat检测
if [ -e ./system.new.dat.1 ];then
  echo "检测到分段system.new.dat，正在合并"
  if [ -e ./system.new.dat.1 ];then
    cat ./system.new.dat.{1..999} 2>/dev/null >> ./system.new.dat
    rm -rf ./system.new.dat.{1..999}
    python $bin/sdat2img.py system.transfer.list system.new.dat ./system.img
    mv ./system.img ../
  fi

  if [ -e ./vendor.new.dat.1 ];then
    echo "检测到分段vendor.new.dat，正在合并"
    cat ./vendor.new.dat.{1..999} 2>/dev/null >> ./vendor.new.dat
    rm -rf ./vendor.new.dat.{1..999}
    python $bin/sdat2img.py vendor.transfer.list vendor.new.dat ./vendor.img
    mv ./vendor.img ../
  fi

  if [ -e ./product.new.dat.1 ];then
    echo "检测到分段product.new.dat，正在合并"
    cat ./product.new.dat.{1..999} 2>/dev/null >> ./product.new.dat
    rm -rf ./product.new.dat.{1..999}
    python $bin/sdat2img.py product.transfer.list product.new.dat ./product.img
    mv ./product.img ../
  fi

  if [ -e ./system_ext.new.dat.1 ];then
    echo "检测到分段system_ext.new.dat，正在合并"
    cat ./system_ext.new.dat.{1..999} 2>/dev/null >> ./system_ext.new.dat
    rm -rf ./product.new.dat.{1..999}
    python $bin/sdat2img.py system_ext.transfer.list system_ext.new.dat ./system_ext.img
    mv ./system_ext.img ../
  fi  

  if [ -e ./odm.new.dat.1 ];then
    echo "检测到分段odm.new.dat，正在合并"
    cat ./odm.new.dat.{1..999} 2>/dev/null >> ./odm.new.dat
    rm -rf ./odm.new.dat.{1..999}
    python $bin/sdat2img.py odm.transfer.list odm.new.dat ./odm.img
    mv ./odm.img ../
  fi    
else
  if [ -e ./system.new.dat ];then
    echo "正在解压system.new.dat"
    python $bin/sdat2img.py system.transfer.list system.new.dat ./system.img
    mv ./system.img ../
  fi
  
  if [ -e ./vendor.new.dat ];then
    echo "正在解压vendor.new.dat"
    python $bin/sdat2img.py vendor.transfer.list vendor.new.dat ./vendor.img
    mv ./vendor.img ../
  fi

  if [ -e ./product.new.dat ];then
    echo "正在解压product.new.dat"
    python $bin/sdat2img.py product.transfer.list product.new.dat ./product.img
    mv ./product.img ../
  fi
 
  if [ -e ./system_ext.new.dat ];then
    echo "正在解压system_ext.new.dat"
    python $bin/sdat2img.py system_ext.transfer.list system_ext.new.dat ./system_ext.img
    mv ./system_ext.img ../
  fi

 if [ -e ./odm.new.dat ];then
   echo "正在解压odm.new.dat"
   python $bin/sdat2img.py odm.transfer.list odm.new.dat ./odm.img
   mv ./odm.img ../
  fi
fi

#img检测
if [ -e ./system.img ];then
  mv ./*.img ../
fi

cd $LOCALDIR

make_type=$1

if [ -e ./system.img ];then
  case $make_type in
    "A"|"a") 
      ./SGSI.sh "A"
      ./workspace_cleanup.sh
      ;;
    "AB"|"ab")  
      ./SGSI.sh "AB"
      ./workspace_cleanup.sh   
      ;;
    *)
      echo "error!"
      exit
      ;;
    esac   
  exit
else
  echo "未检测到system.img, 无法制作SGSI！"
  exit
fi
