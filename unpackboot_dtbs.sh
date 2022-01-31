#/bin/bash

LOCALDIR=`cd "$( dirname ${BASH_SOURCE[0]} )" && pwd`
cd $LOCALDIR
source ./bin.sh

if [ ! -e $LOCALDIR/boot.img ];then
  echo "boot.img does not exist!"
  exit
fi

cp -frp ./boot.img $bin/extract-dtb
cd $bin/extract-dtb
echo "Extracting Kernel dtbs..."
rm -rf ./dtbs
mkdir ./dtbs
python3 ./extract-dtb.py ./boot.img -o ./dtbs
if [ $? = "1" ];then
  echo "Failed to extract"
  rm -rf ./boot.img
  rm -rf ./dtbs
else
  echo "Extraction completed, output to $LOCALDIR/dtbs directory"
  rm -rf ./boot.img
  rm -rf $LOCALDIR/dtbs
  mv ./dtbs $LOCALDIR
  chmod 777 -R $LOCALDIR/dtbs
fi
cd $LOCALDIR
