#!/bin/bash

LOCALDIR=$(cd "$(dirname ${BASH_SOURCE[0]})" && pwd)
cd $LOCALDIR
source ./bin.sh

bb="$bin/busybox"
toolsdir="$bin/boot_tools"
cpio="$toolsdir/cpio"
lz4="$toolsdir/lz4"
aik="$toolsdir/AIK"
image_type="$1"
final_outdir="$LOCALDIR/${image_type}_out"
image="${image_type}.img"


usage() {
  cat <<EOF
$0 <image_type>
  image_type: boot or vendor_boot
EOF
  exit 1
}

abort() {
  echo -e $*
  exit 1
}

extract_ramdisk() {
  local ramdisk_file="$1"
  local ramdisk_dir="${image_type}_ramdisk"
  local comp
  comp=$($toolsdir/magiskboot decompress ramdisk.cpio 2>&1 | sed -n 's;.*\[\(.*\)\];\1;p')
  local compext=".${comp}"

  echo "$comp" >ramdisk_comp

  rm -rf $ramdisk_dir
  mkdir -p $ramdisk_dir

  case $comp in
  gzip) compext=".gz" ;;
  lzop) compext=".lzo" ;;
  xz) ;;
  lzma) ;;
  bzip2) compext=".bz2" ;;
  lz4) compext=".lz4" ;;
  lz4_legacy) compext=".lz4" ;;
  raw) compext="" ;;
  *) abort "Unsupport compressed type!" ;;
  esac

  if [ -n "$compext" ]; then
    mv -f ramdisk.cpio ramdisk.cpio$compext
    $toolsdir/magiskboot decompress ramdisk.cpio$compext ramdisk.cpio
    [ $? != 0 ] && abort "ramdisk decompress failed!"
    mv -f ramdisk.cpio$compext .ramdisk.cpio$compext.orig
  fi

  cd $ramdisk_dir
  $toolsdir/magiskboot cpio "../ramdisk.cpio" extract >/dev/null 2>&1
  [ $? != 0 ] && abort "ramdisk extract failed!"
  [ -z "$compext" ] && mv -f ../ramdisk.cpio ../ramdisk.cpio.orig

  cd $LOCALDIR
  return 0
}

extract_with_aik() {
  rm -rf $final_outdir
  mkdir -p $final_outdir
  cp -frp $image $aik/
  cd $aik
  sudo ./unpackimg.sh $image
  if [ $? = "0" ]; then
    rm -rf $image
    mv -f ramdisk/ $final_outdir/
    mv -f split_img/ $final_outdir/
    echo "aik" >$final_outdir/extract_prog
    echo "提取成功, 輸出目录: $final_outdir"
  else
    echo "方案1提取失败"
    rm -rf $image
    ./cleanup.sh
    return 1
  fi

  return 0
}

extract_with_magiskboot() {
  rm -rf $final_outdir
  mkdir -p $final_outdir
  cp -frp $toolsdir/magiskboot $final_outdir/
  cp -frp $image $final_outdir/
  cd $final_outdir

  ./magiskboot unpack -h $image
  if [ $? = "0" ]; then
    rm -rf $image magiskboot
    ramdisk_file=$(ls | grep "ramdisk.cpio")
    [ -f $ramdisk_file ] && extract_ramdisk "$ramdisk_file"
    cd $final_outdir # 因为 magiskboot 提取 ramdisk 的原因, 必须二次cd一次否则会目录错误
    echo "magiskboot" >$final_outdir/extract_prog
    echo "提取成功, 輸出目录: $final_outdir"
  else
    echo "方案2提取失败"
    cd $LOCALDIR
    rm -rf $final_outdir
    return 1
  fi

  cd $LOCALDIR
  return 0
}

[ $# != 1 ] && usage
[ ! -f $LOCALDIR/$image ] && abort "$LOCALDIR/$image not found"

extract_with_magiskboot
[ $? != 0 ] && extract_with_aik

chmod 777 -R $final_outdir
