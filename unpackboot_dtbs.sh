#/bin/bash

LOCALDIR=`cd "$( dirname $0 )" && pwd`
cd $LOCALDIR
source ./bin.sh

if [ ! -e $LOCALDIR/boot.img ];then
  echo "boot.img不存在！"
  exit
fi

cp -frp ./boot.img $bin/extract-dtb
cd $bin/extract-dtb
echo "正在提取Kernel dtbs..."
rm -rf ./dtbs
mkdir ./dtbs
python3 ./extract-dtb.py ./boot.img -o ./dtbs
if [ $? = "1" ];then
  echo "提取失败"
  rm -rf ./boot.img
  rm -rf ./dtbs
else
  echo "提取完成，已输出至$LOCALDIR/dtbs目录"
  rm -rf ./boot.img
  rm -rf $LOCALDIR/dtbs
  mv ./dtbs $LOCALDIR
  chmod 777 -R $LOCALDIR/dtbs
fi
cd $LOCALDIR
