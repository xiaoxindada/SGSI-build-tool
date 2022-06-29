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

repack_ramdisk() {
  local ramdisk_dir="${image_type}_ramdisk"
  local ramdisk_comp=$(cat $final_outdir/ramdisk_comp)
  local comp_level="-9"
  local repackcmd="$ramdisk_comp $comp_level"
  local compext=".${ramdisk_comp}"

  case $ramdisk_comp in
  gzip) compext=".gz" ;;
  lzop) compext=".lzo" ;;
  xz)
    repackcmd="xz $comp_level -Ccrc32"
    ;;
  lzma) repackcmd="xz $comp_level -Flzma" ;;
  bzip2) compext=".bz2" ;;
  lz4)
    repackcmd="$toolsdir/lz4 $comp_level"
    compext=".lz4"
    ;;
  lz4_legacy)
    repackcmd="$toolsdir/lz4 $comp_level -l"
    compext=".lz4"
    ;;
  raw)
    repackcmd="cat"
    compext=""
    ;;
  *) abort "ramdisk unsupported compress format!" ;;
  esac

  cd $final_outdir/$ramdisk_dir
  local repack_ramdisk_cmd="find . | $cpio -R 0:0 -H newc -o 2>/dev/null | $repackcmd > ../ramdisk-new.cpio$compext"
  
  echo "rebacking ramdisk-new.cpio$compext ..."
  eval $repack_ramdisk_cmd
  [ $? != 0 ] && abort "repack ramdisk failed!"
  if [[ -f "../ramdisk-new.cpio$compext" && $(cat $final_outdir/extract_prog) == "magiskboot" ]];then
    echo "use magiskboot repack"
    echo "copy ramdisk-new.cpio$compext to ramdisk.cpio ..."
    cp -af "../ramdisk-new.cpio$compext" "../ramdisk.cpio"
  fi
  cd $LOCALDIR
}

repack_with_aik() {
  mv -f $final_outdir/* $aik
  cd $aik
  ./repackimg.sh --forceelf #--origsize
  if [ -f unpadded-new.img ]; then
    mv -f unpadded-new.img $final_outdir
  fi
  mv -f image-new.img new-boot.img
  mv -f new-boot.img $final_outdir
  ./cleanup.sh
  cd $LOCALDIR

  if [ -s $final_outdir/new-boot.img ]; then
    echo "生成文件: $final_outdir/new-boot.img"
  fi

}

repack_with_magisk() {
  local ramdisk_comp=".$(cat $final_outdir/ramdisk_comp | grep -v "raw")"

  cp -frp $toolsdir/magiskboot $final_outdir/
  cp -frp $image $final_outdir/
  cd $final_outdir
  ./magiskboot repack ${image_type}.img
  rm -rf magiskboot
  cd $LOCALDIR

  if [ -s $final_outdir/new-boot.img ]; then
    [ $image_type = "vendor_boot" ] && mv -f $final_outdir/new-boot.img $final_outdir/new-${image}
    echo "生成文件: $final_outdir/new-${image}"
  fi
}

[ $# != 1 ] && usage
[ ! -f $LOCALDIR/$image ] && echo "$LOCALDIR/$image not found" && exit 1

if [ ! -f $final_outdir/extract_prog ]; then
  abort "Need to extract the $image first"
fi

if [ $(cat $final_outdir/extract_prog) = "aik" ]; then
  repack_with_aik
elif [ $(cat $final_outdir/extract_prog) = "magiskboot" ]; then
  repack_ramdisk
  repack_with_magisk
fi

chmod 777 -R $final_outdir
