#!/bin/bash

LOCALDIR=`cd "$( dirname $0 )" && pwd`
cd $LOCALDIR
WORKSPACE=$LOCALDIR/../../workspace
IMAGESDIR=$WORKSPACE/images
TARGETDIR=$WORKSPACE/out

systemdir="$TARGETDIR/system/system"
configdir="$TARGETDIR/config"

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

# 清理apex默认状态
sed -i '/ro.apex.updatable/d' $systemdir/build.prop
sed -i '/ro.apex.updatable/d' $systemdir/product/etc/build.prop
sed -i '/ro.apex.updatable/d' $systemdir/system_ext/etc/build.prop

apex_flatten() {
  # 强行扁平化apex
  echo "ro.apex.updatable=false" >> $systemdir/product/etc/build.prop

  # 清理apex
  apex_files=$(ls $systemdir/apex | grep ".apex$")
  for apex in $apex_files ;do
    if [ -f $systemdir/apex/$apex ];then
      echo "skip remove apex"
     # rm -rf $systemdir/apex/$apex
    fi
  done

  # 当启用apex扁平化时 我们不需要cts的apex存在
  for cts_files in $(find $systemdir/apex -type d -name "*" | grep -E "apex.cts.*");do
    [ -z $cts_files ] && continue
    rm -rf $cts_files
  done
}
apex_flatten

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

# 修补不同vndk版本所需要的vintf片段
manifest_file="$systemdir/system_ext/etc/vintf/manifest.xml"
if [ -f $manifest_file ];then
   sed -i "/<\/manifest>/d" $manifest_file
   cat $LOCALDIR/manifest.patch >> $manifest_file
   echo "" >> $manifest_file
   echo "</manifest>" >> $manifest_file
fi
