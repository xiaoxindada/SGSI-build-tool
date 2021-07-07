#!/bin/bash

LOCALDIR=`cd "$( dirname $0 )" && pwd`
cd $LOCALDIR

systemdir="$LOCALDIR/../../out/system/system"
configdir="$LOCALDIR/../../out/config"

# apex检测
apex_check() {
  apex_extract=""
  if ls $systemdir/apex | grep -q ".apex$" ;then
     echo "检测到apex"
  fi
  if ! (ls $systemdir/apex | grep -q ".apex$") ;then
    echo "检测到当前apex为扁平化状态"
    rm -rf $systemdir/apex/com.android.vndk.current
    tar -xf $LOCALDIR/com.android.vndk.current.tar -C $systemdir/apex/
  fi
}  
apex_check
echo "正在提取额外apex中"
7z x -y $LOCALDIR/com.android.vndk.v29.apex.7z -o$systemdir/apex/ > /dev/null 2>&1
7z x -y $LOCALDIR/com.android.vndk.v30.apex.7z -o$systemdir/apex/ > /dev/null 2>&1
cd $LOCALDIR/../apex_flat
./apex_extractor.sh "$systemdir/apex"
cd $LOCALDIR

# 强行扁平化apex
sed -i '/ro.apex.updatable/d' $systemdir/build.prop
sed -i '/ro.apex.updatable/d' $systemdir/product/etc/build.prop
sed -i '/ro.apex.updatable/d' $systemdir/system_ext/etc/build.prop
echo "ro.apex.updatable=false" >> $systemdir/product/etc/build.prop

# 清理apex
apex_files=$(ls $systemdir/apex | grep ".apex$")
for apex in $apex_files ;do
  if [ -f $systemdir/apex/$apex ];then
    rm -rf $systemdir/apex/$apex
  fi
done

# 创建vndk链接
rm -rf $systemdir/lib/vndk-29 $systemdir/lib/vndk-sp-29
rm -rf $systemdir/lib/vndk-28 $systemdir/lib/vndk-sp-28
rm -rf $systemdir/lib/vndk-30 $systemdir/lib/vndk-sp-30
rm -rf $systemdir/lib64/vndk-29 $systemdir/lib64/vndk-sp-29
rm -rf $systemdir/lib64/vndk-28 $systemdir/lib64/vndk-sp-28
rm -rf $systemdir/lib64/vndk-30 $systemdir/lib64/vndk-sp-30

ln -s  /apex/com.android.vndk.v29/lib $systemdir/lib/vndk-29
ln -s  /apex/com.android.vndk.v28/lib $systemdir/lib/vndk-28
ln -s  /apex/com.android.vndk.v30/lib $systemdir/lib/vndk-30
ln -s  /apex/com.android.vndk.v29/lib $systemdir/lib/vndk-sp-29
ln -s  /apex/com.android.vndk.v28/lib $systemdir/lib/vndk-sp-28
ln -s  /apex/com.android.vndk.v30/lib $systemdir/lib/vndk-sp-30

ln -s  /apex/com.android.vndk.v29/lib64 $systemdir/lib64/vndk-29
ln -s  /apex/com.android.vndk.v28/lib64 $systemdir/lib64/vndk-28
ln -s  /apex/com.android.vndk.v30/lib64 $systemdir/lib64/vndk-30
ln -s  /apex/com.android.vndk.v29/lib64 $systemdir/lib64/vndk-sp-29
ln -s  /apex/com.android.vndk.v28/lib64 $systemdir/lib64/vndk-sp-28
ln -s  /apex/com.android.vndk.v30/lib64 $systemdir/lib64/vndk-sp-30
