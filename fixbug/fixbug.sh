#!/bin/bash

LOCALDIR=`cd "$( dirname $0 )" && pwd`
cd $LOCALDIR

./rm.sh > /dev/null 2>&1

echo "
--------------------

支持的ROM:

Pixel
--------------------
"
while true ;do
  read -p "请选择系统种类(用小写输出): " fix
  case "$fix" in
   "pixel")
      echo "正在修复"
      ./pixel.sh
      break;;
    *)
      echo "输入错误，清重试"
      ;;
  esac
done
