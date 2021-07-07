#!/bin/bash

LOCALDIR=`cd "$( dirname $0 )" && pwd`
cd $LOCALDIR

systemdir="$LOCALDIR/../../out/system/system"
configdir="$LOCALDIR/../../out/config"

echo "正在提取额外apex中"
7z x -y $LOCALDIR/com.android.vndk.v28.apex.7z -o$systemdir/apex/ > /dev/null 2>&1
cd $LOCALDIR/../apex_flat
./apex_extractor.sh "$systemdir/apex"
cd $LOCALDIR

# 强行扁平化apex
sed -i '/ro.apex.updatable/d' $systemdir/build.prop
sed -i '/ro.apex.updatable/d' $systemdir/product/etc/build.prop
sed -i '/ro.apex.updatable/d' $systemdir/system_ext/etc/build.prop
#echo "ro.apex.updatable=false" >> $systemdir/product/etc/build.prop 

# 清理apex
apex_files=$(ls $systemdir/apex | grep ".apex$")
rm -rf $systemdir/apex/*v29*
rm -rf $systemdir/apex/*v30*
for apex in $apex_files ;do
  if [ -f $systemdir/apex/$apex ];then
    rm -rf $systemdir/apex/$apex
  fi
done
