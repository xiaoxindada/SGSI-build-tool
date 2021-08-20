#!/bin/bash

LOCALDIR=`cd "$( dirname ${BASH_SOURCE[0]} )" && pwd`
cd $LOCALDIR
source ./bin.sh

read -p "请输入你要查看avb数据的img: " img
rm -rf ./$img'_avb.txt'
$bin/avbtool.py info_image --image ./$img > ./$img'_avb.txt'
