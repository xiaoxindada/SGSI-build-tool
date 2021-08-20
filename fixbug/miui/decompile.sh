#!/bin/bash

LOCALDIR=`cd "$( dirname ${BASH_SOURCE[0]} )" && pwd`
cd $LOCALDIR

rm -rf ./services.jar.out
echo "正在反编译services.jar"
java -jar ../apktool.jar d ./services.jar > /dev/null 2>&1

#开机报错提示去除
BaseErrorDialog="$(grep 'invoke-virtual {v0}, Lcom/android/server/am/BaseErrorDialog;->show()V' ./services.jar.out/smali_classes2/ -ril)"

sed -i '/invoke-virtual {v0}, Lcom\/android\/server\/am\/BaseErrorDialog;->show()V/d' $BaseErrorDialog

echo "正在回编译services.jar"
java -jar ../apktool.jar b ./services.jar.out > /dev/null 2>&1

cp -frp ./services.jar.out/dist/services.jar ../../out/system/system/framework/
rm -rf ./services.jar
