#!/bin/bash

LOCALDIR=`cd "$( dirname ${BASH_SOURCE[0]} )" && pwd`
cd $LOCALDIR
source $LOCALDIR/../../bin.sh
source $LOCALDIR/../../language_helper.sh

systemdir="$TARGETDIR/system/system"
configdir="$TARGETDIR/config"

# Detect APEX State
apex_check() {
  apex_extract=""
  if ls $systemdir/apex | grep -q ".apex$" ;then
     echo "$DETECTED_APEX"
  fi
  if ! (ls $systemdir/apex | grep -q ".apex$") ;then
    echo "$DETECTED_FLATTEN_APEX"
    rm -rf $systemdir/apex/com.android.vndk.current
    tar -xf $LOCALDIR/com.android.vndk.current.tar -C $systemdir/apex/
  fi
}  
apex_check
echo "$EXTRACTING_EXTRA_APEX"
7z x -y $LOCALDIR/com.android.vndk.v29.apex.7z -o$systemdir/apex/ > /dev/null 2>&1
7z x -y $LOCALDIR/com.android.vndk.v30.apex.7z -o$systemdir/apex/ > /dev/null 2>&1
cd $bin/apex_tools
./apex_extractor.sh "$TARGETDIR" "$systemdir/apex"
cd $LOCALDIR

# Clean up default apex state
sed -i '/ro.apex.updatable/d' $systemdir/build.prop
sed -i '/ro.apex.updatable/d' $systemdir/product/etc/build.prop
sed -i '/ro.apex.updatable/d' $systemdir/system_ext/etc/build.prop

apex_flatten() {
  # Force using flatten apex
  echo "ro.apex.updatable=false" >> $systemdir/product/etc/build.prop

  # Cleanup apex
  apex_files=$(ls $systemdir/apex | grep ".apex$")
  for apex in $apex_files ;do
    if [ -f $systemdir/apex/$apex ];then
      echo "skip remove apex"
     # rm -rf $systemdir/apex/$apex
    fi
  done

  # Removing cts's apex when flatten apex is enabled
  for cts_files in $(find $systemdir/apex -type d -name "*" | grep -E "apex.cts.*");do
    [ -z $cts_files ] && continue
    rm -rf $cts_files
  done
}
apex_flatten

# Create vndk symlinks
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

# Fix vintf for different vndk version
manifest_file="$systemdir/system_ext/etc/vintf/manifest.xml"
if [ -f $manifest_file ];then
   sed -i "/<\/manifest>/d" $manifest_file
   cat $LOCALDIR/manifest.patch >> $manifest_file
   echo "" >> $manifest_file
   echo "</manifest>" >> $manifest_file
fi
