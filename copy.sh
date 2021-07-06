#!/bin/bash

LOCALDIR=`cd "$( dirname $0 )" && pwd`
cd $LOCALDIR

mkdir -p ./SGSI
cp -frp ./other/* ./SGSI/
for i in Patch{1..3};do
  if [ -d ./SGSI/$i ];then
    cd ./SGSI/$i
    echo "正在打包$i中..."
    zip -r ../$i.zip ./* 2&>/dev/null
    cd $LOCALDIR
    rm -rf ./SGSI/$i
  fi
done
chmod 777 -R ./SGSI
