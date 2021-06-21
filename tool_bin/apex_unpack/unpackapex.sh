#!/bin/bash

if [ -e ../../out/system/system/apex ];then
 echo "正在解压apex......"
 ./apex_extractor.sh "../../out/system/system/apex"
fi

if [ -e ../../out/system/system/system_ext/apex ];then
 echo "正在解压system_ext/apex"
 ./apex_extractor.sh "../../out/system/system/system_ext/apex"
fi
