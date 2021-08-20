#!/bin/bash

# Copyright (C) 2021 Xiaoxindada <2245062854@qq.com>

LOCALDIR=`cd "$( dirname ${BASH_SOURCE[0]} )" && pwd`
cd $LOCALDIR
HOST=$(uname)
platform=$(uname -m)
libs_dir="$LOCALDIR/../../$HOST/$platform/lib64"

usage() {
cat <<EOT
Usage:
$0 <Unsign.apk Path> [Other args]
  Unsign.apk Path: Unsign.apk Path or Resign.apk Path
  
  Other args:
    [--ks2x509]: Using custom .jks to sign apk
    [--custom_keys]: Using custom .x509.pem .pk8 to sign apk
EOT
}

if [ "$1" = "" ];then
  usage
  exit
fi

case $1 in
  "-h"|"--help")
    usage
    exit
    ;;
esac

args=$@
ks2x509="false"
custom_keys="false"
base_apk="${1##*/}"

if (echo $args | grep -qo -- '--ks2x509') ;then
  ks2x509="true"
fi

if (echo $args | grep -qo -- '--custom_keys') ;then
  custom_keys="true"
fi

case $ks2x509 in
  "true")
    read -p "请输入key_path: " key_path
    read -p "请输入key_alias: " key_alias
    read -p "请输入key_password: " key_password
    
    ks2x509() {
     local key_path="$1"
     local key_alias="$2"
     local key_password="$3"
      
      echo "java -Xmx512m -jar ks2x509.jar $key_path $key_alias $key_password"
      java -Xmx512m -jar ks2x509.jar $key_path $key_alias $key_password 
    }
    ks2x509 "$key_path" "$key_alias" "$key_password"
    exit
    ;;
esac
    
case $custom_keys in
  "false")
    echo -e "\033[33m Use AOSP Keys... \033[0m"
    java -Xmx512m -jar -Djava.library.path="$libs_dir" ./signapk.jar -w ./AOSP_security/verity.x509.pem ./AOSP_security/verity.pk8 ${base_apk} sign_${base_apk}
    ;;
  "true")
    custom_x509_pem="$3"
    shift 3
    custom_pk8="$1"
    shift
    
    echo -e "\033[33m Use Custom Keys... \033[0m"
    java -Xmx512m -jar -Djava.library.path="$libs_dir" ./signapk.jar -w ${custom_x509_pem} ${custom_pk8} ${base_apk} sign_${base_apk}
    ;;
esac
