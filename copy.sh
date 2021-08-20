#!/bin/bash

LOCALDIR=`cd "$( dirname ${BASH_SOURCE[0]} )" && pwd`
cd $LOCALDIR
source ./language_helper.sh

mkdir -p ./SGSI
cp -frp ./other/* ./SGSI/
for i in Patch{1..3};do
  if [ -d ./SGSI/$i ];then
    cd ./SGSI/$i
    echo "$GENERATRING_STR $i"
    zip -r ../$i.zip ./* 2&>/dev/null
    cd $LOCALDIR
    rm -rf ./SGSI/$i
  fi
done
chmod 777 -R ./SGSI
