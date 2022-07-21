#!/bin/bash

LOCALDIR=$(cd "$(dirname ${BASH_SOURCE[0]})" && pwd)
cd $LOCALDIR
source $LOCALDIR/../../bin.sh
source $LOCALDIR/../../language_helper.sh

systemdir="$TARGETDIR/system/system"
configdir="$TARGETDIR/config"
current_sdk_ver=$(cat $systemdir/build.prop | grep "ro.build.version.sdk" | head -n 1 | cut -d "=" -f 2)

# Detect APEX State
apex_check() {
  apex_extract=""
  if ls $systemdir/apex | grep -q ".apex$"; then
    echo "$DETECTED_APEX"
  fi
  if ! (ls $systemdir/apex | grep -q ".apex$"); then
    echo "$DETECTED_FLATTEN_APEX"
  fi
}

apex_check
echo "$EXTRACTING_EXTRA_APEX"

# Prebuilt vndk.current
rm -rf $systemdir/apex/com.android.vndk.current*
if [ $current_sdk_ver = 31 ]; then
  if [ ! -f $systemdir/com.android.vndk.v31.apex ]; then
    7z x -y $LOCALDIR/com.android.vndk.v31.apex.7z -o$systemdir/apex/ >/dev/null 2>&1
    mv $systemdir/apex/com.android.vndk.v31.apex $systemdir/apex/com.android.vndk.current.apex
  fi
fi
if [ $current_sdk_ver = 32 ]; then
  if [ ! -f $systemdir/com.android.vndk.v32.apex ]; then
    7z x -y $LOCALDIR/com.android.vndk.v32.apex.7z -o$systemdir/apex/ >/dev/null 2>&1
    mv $systemdir/apex/com.android.vndk.v32.apex $systemdir/apex/com.android.vndk.current.apex
  fi
fi

# different vndk version
if [ ! -f $systemdir/com.android.vndk.v29.apex ]; then
  7z x -y $LOCALDIR/com.android.vndk.v29.apex.7z -o$systemdir/apex/ >/dev/null 2>&1
fi
if [ ! -f $systemdir/com.android.vndk.v30.apex ]; then
  7z x -y $LOCALDIR/com.android.vndk.v30.apex.7z -o$systemdir/apex/ >/dev/null 2>&1
fi
if [ $current_sdk_ver = 32 ]; then
  if [ ! -f $systemdir/com.android.vndk.v31.apex ]; then
    7z x -y $LOCALDIR/com.android.vndk.v31.apex.7z -o$systemdir/apex/ >/dev/null 2>&1
  fi
fi

cd $bin/apex_tools
./apex_extractor.sh "$TARGETDIR" "$systemdir/apex"
cd $LOCALDIR

# Clean up default apex state
sed -i '/ro.apex.updatable/d' $systemdir/build.prop
sed -i '/ro.apex.updatable/d' $systemdir/product/etc/build.prop
sed -i '/ro.apex.updatable/d' $systemdir/system_ext/etc/build.prop

apex_flatten() {
  # Force use flatten apex
  echo "" >>$systemdir/product/etc/build.prop
  echo "# Apex state" >>$systemdir/product/etc/build.prop
  echo "ro.apex.updatable=false" >>$systemdir/product/etc/build.prop

  echo "$ENABLE_CLEAN_APEX_FILES"
  local apex_files=$(ls $systemdir/apex | grep ".apex$")
  for apex in $apex_files; do
    if [ -f $systemdir/apex/$apex ]; then
      rm -rf $systemdir/apex/$apex
    fi
  done

  # Not mount apex setup
  [ -f $systemdir/etc/init/apex-sharedlibs.rc ] && rm -rf $systemdir/etc/init/apex-sharedlibs.rc
}

apex_enable() {
  # Force enable apex
  echo "" >>$systemdir/product/etc/build.prop
  echo "# Apex state" >>$systemdir/product/etc/build.prop
  echo "ro.apex.updatable=true" >>$systemdir/product/etc/build.prop
  echo "$ENABLE_CLEAN_APEX_DIRS"

  local apex_dirs=$(find $systemdir/apex -maxdepth 1 -type d | grep -v "$systemdir/apex$")
  for apex_dir in $apex_dirs; do
    if [ -d $apex_dir ]; then
      rm -rf $apex_dir
    fi
  done
}

if [ $(cat $TARGETDIR/apex_state) = true ]; then
  apex_enable
elif [ $(cat $TARGETDIR/apex_state) = false ]; then
  apex_flatten
fi

# Create vndk symlinks
rm -rf $systemdir/lib/vndk-29 $systemdir/lib/vndk-sp-29
rm -rf $systemdir/lib/vndk-30 $systemdir/lib/vndk-sp-30
rm -rf $systemdir/lib/vndk-31 $systemdir/lib/vndk-sp-31
if [ $current_sdk_ver = 32 ]; then
  rm -rf $systemdir/lib/vndk-32 $systemdir/lib/vndk-sp-32
fi

rm -rf $systemdir/lib64/vndk-29 $systemdir/lib64/vndk-sp-29
rm -rf $systemdir/lib64/vndk-30 $systemdir/lib64/vndk-sp-30
rm -rf $systemdir/lib64/vndk-31 $systemdir/lib64/vndk-sp-31
if [ $current_sdk_ver = 32 ]; then
  rm -rf $systemdir/lib64/vndk-32 $systemdir/lib64/vndk-sp-32
fi

ln -s /apex/com.android.vndk.v29/lib $systemdir/lib/vndk-29
ln -s /apex/com.android.vndk.v29/lib $systemdir/lib/vndk-sp-29

ln -s /apex/com.android.vndk.v29/lib64 $systemdir/lib64/vndk-29
ln -s /apex/com.android.vndk.v29/lib64 $systemdir/lib64/vndk-sp-29

# Fix vintf for different vndk version
manifest_file="$systemdir/system_ext/etc/vintf/manifest.xml"
if [ -f $manifest_file ]; then
  sed -i "/<\/manifest>/d" $manifest_file
  cat >>"$manifest_file" <<EOF
    <vendor-ndk>
        <version>29</version>
    </vendor-ndk>
    <vendor-ndk>
        <version>30</version>
    </vendor-ndk>
EOF
  if [ $current_sdk_ver = 32 ]; then
    cat >>"$manifest_file" <<EOF
    <vendor-ndk>
        <version>31</version>
    </vendor-ndk>
EOF
  fi
  echo "" >>$manifest_file
  echo "</manifest>" >>$manifest_file
fi
