#!/bin/bash

LOCALDIR=`cd "$( dirname $0 )" && pwd`
cd $LOCALDIR

usage() {
  echo "Usage: $0 <unsignapk_name>"
} 

if [ "$1" = "" ];then
  echo "error!"
  usage
  exit
fi

apkname="$1"
HOST=$(uname)
platform=$(uname -m)
libs_dir="$LOCALDIR/../../$HOST/$platform/lib64"

java -Xmx512m -jar -Djava.library.path="$libs_dir" ./signapk.jar -w ./AOSP_security/verity.x509.pem ./AOSP_security/verity.pk8 $1 sign_${apkname}

