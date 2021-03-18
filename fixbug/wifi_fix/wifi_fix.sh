#!/bin/bash

LOCALDIR=`cd "$( dirname $0 )" && pwd`
cd $LOCALDIR

systemdir="../../out/system/system"
configdir="../../out/config"

rm -rf ./wifi-service.jar.out
rm -rf ./tmp
mkdir ./tmp

if [ -e ./wifi-service.jar ];then
  echo "正在反编译wifi-service.jar"
  java -jar ../apktool.jar d ./wifi-service.jar > /dev/null 2>&1
  SupplicantStaIfaceHal="./wifi-service.jar.out/smali/com/android/server/wifi/SupplicantStaIfaceHal.smali"
  cp -frp $SupplicantStaIfaceHal ./tmp/SupplicantStaIfaceHal.smali
  rm -rf $SupplicantStaIfaceHal
    while IFS= read -r line ;do
      $flag && echo "$line" >> $SupplicantStaIfaceHal
      if [ "$line" == ".method public startDaemon()Z" ]; then
        flag=false
      fi
      if ! $flag && [ "$line" == ".end method" ]; then
        flag=true
        cat ./com_android_server_wifi_SupplicantStaIfaceHal.patch >> $SupplicantStaIfaceHal
        echo "$line" >> $SupplicantStaIfaceHal
      fi
    done  < ./tmp/SupplicantStaIfaceHal.smali
  echo "wifi修复完成"
  echo "正在回编译wifi-service.jar"
  java -jar ../apktool.jar b ./wifi-service.jar.out > /dev/null 2>&1
fi
 
cp -frp ./wpa_supplicant $systemdir/bin/
cat ./plat_file_contexts >> $systemdir/etc/selinux/plat_file_contexts
cat ./add_rw-system.sh >> $systemdir/bin/rw-system.sh
cat ./fs >> $configdir/system_fs_config
cat ./contexts >> $configdir/system_file_contexts
