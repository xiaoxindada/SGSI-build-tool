#!/bin/bash

LOCALDIR=`cd "$( dirname $0 )" && pwd`
cd $LOCALDIR

systemdir="../../out/system/system"
configdir="../../out/config"

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

# 扁平化apex
sed -i '/ro.apex.updatable/d' $systemdir/build.prop
sed -i '/ro.apex.updatable/d' $systemdir/product/build.prop
sed -i '/ro.apex.updatable/d' $systemdir/system_ext/build.prop
echo "" >> $systemdir/product/build.prop
echo "ro.apex.updatable=false" >> $systemdir/product/build.prop
rm -rf $systemdir/apex/com.android.vndk.current*
7z x ./vndk.7z -o$systemdir/ > /dev/null 2>&1
cd $bin/apex_tools/
./apex_extractor.sh "$systemdir/apex"
if [ -d $systemdir/system_ext/apex ]; then
./apex_extractor.sh "$systemdir/system_ext/apex"
fi
cd $LOCALDIR
# 清理多余的apex
rm -rf $systemdir/apex/*.apex
[ -d $systemdir/system_ext/apex ] && rm -rf $systemdir/system_ext/apex/*.apex
