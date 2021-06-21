#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
# Originally by @xiaolu

C_OUT="\033[0;1m"
C_ERR="\033[31;1m"
C_CLEAR="\033[0;0m"
pout() {
    printf "${C_OUT}${*}${C_CLEAR}\n"
}
perr() {
    printf "${C_ERR}${*}${C_CLEAR}\n"
}
unpack_complete()
{
    [ ! -z $format ] && echo format=$format >> ../img_info
    pout "Unpack completed."
    exit
}
usage()
{
    pout "\n >>  Unpack boot.img tool, Originally by @xiaolu  <<"
	pout "     - w/ MTK Header Detection, by @carlitros900"
    pout "-----------------------------------------------------"
    perr " Not enough parameters or parameter error!"
    pout " unpack boot.img & decompress ramdisk:"
	pout "    $(basename $0) [img] [output dir]"
    pout "    $(basename $0) boot.img boot20130905\n"
    exit
}
#decide action
[ $# -lt 2 ] || [ $# -gt 3 ] && usage

tempdir="$(readlink -f $2)"
mkdir -p $tempdir
pout "Unpack & decompress $1 to $2"

bb="busybox"

# Get boot.img info
cp -f $1 $tempdir/
cd $tempdir
bootimg="$(basename $1)"
offset=$(grep -abo "ANDROID!\|VNDRBOOT" $bootimg | cut -f 1 -d :)
[ -z $offset ] && exit
if [ $offset -gt 0 ]; then
    dd if=$bootimg of=bootimg bs=$offset skip=1 2>/dev/null
fi
header_addr=40
VNDRBOOT=false
if grep -qabo VNDRBOOT $bootimg; then
    VNDRBOOT=true
    header_addr=8
fi

kernel_addr=0x$($bb od -A n -X -j 12 -N 4 $bootimg | sed 's/ //g' | sed 's/^0*//g')
ramdisk_addr=0x$($bb od -A n -X -j 20 -N 4 $bootimg | sed 's/ //g' | sed 's/^0*//g')
second_addr=0x$($bb od -A n -X -j 28 -N 4 $bootimg | sed 's/ //g' | sed 's/^0*//g')
tags_addr=0x$($bb od -A n -X -j 32 -N 4 $bootimg | sed 's/ //g' | sed 's/^0*//g')
kernel_size=$($bb od -A n -D -j 8 -N 4 $bootimg | sed 's/ //g')
ramdisk_size=$($bb od -A n -D -j 16 -N 4 $bootimg | sed 's/ //g')
second_size=$($bb od -A n -D -j 24 -N 4 $bootimg | sed 's/ //g')
page_size=$($bb od -A n -D -j 36 -N 4 $bootimg | sed 's/ //g')
dtb_size=$($bb od -A n -D -j 40 -N 4 $bootimg | sed 's/ //g')
dtbo_size=$($bb od -A n -D -j 1632 -N 4 $bootimg | sed 's/ //g')
[ $dtbo_size -gt 0 ] && dtbo_addr=0x$($bb od -A n -X -j 1636 -N 4 $bootimg | sed 's/ //g' | sed -e 's/^0*//g')
cmd_line=$($bb od -A n -S1 -j 64 -N 512 $bootimg)
board=$($bb od -A n -S1 -j 48 -N 16 $bootimg)
version=$($bb od -A n -D -j $header_addr -N 1 $bootimg | sed 's/ //g')
if [ $version -eq 2 ]; then
    dtb_size=$($bb od -A n -D -j 1648 -N 4 $bootimg | sed 's/ //g')
    dtb_addr=0x$($bb od -A n -X -j 1652 -N 4 $bootimg | sed 's/ //g' | sed 's/^0*//g')
elif [ $version -eq 3 ]; then
    page_size=4096
    board=
    kernel_size=0
    kernel_addr=
    second_size=0
    second_addr=
    ramdisk_size=
    ramdisk_addr=
    cmd_line=
    tags_addr=
    dtb_size=0
    dtb_addr=
    if [ "$VNDRBOOT" = "true" ]; then
        kernel_addr=0x$($bb od -A n -X -j 16 -N 4 $bootimg | sed "s/ //g" | sed "s/^0*//g")
        ramdisk_addr=0x$($bb od -A n -X -j 20 -N 4 $bootimg | sed "s/ //g" | sed "s/^0*//g")
        ramdisk_size=$($bb od -A n -D -j 24 -N 4 $bootimg | sed "s/ //g")
        cmd_line=$($bb od -A n -S1 -j 28 -N 2048 $bootimg)
        tags_addr=0x$($bb od -A n -X -j 2076 -N 4 $bootimg | sed "s/ //g" | sed "s/^0*//g")
        dtb_size=$($bb od -A n -D -j 2100 -N 4 $bootimg | sed "s/ //g")
        dtb_addr=0x$($bb od -A n -X -j 2104 -N 4 $bootimg | sed "s/ //g" | sed "s/^0*//g")
    else
        kernel_addr=0x00008000 # To reset the base addr to 0
        kernel_size=$($bb od -A n -D -j 8 -N 4 $bootimg | sed "s/ //g")
        ramdisk_size=$($bb od -A n -D -j 12 -N 4 $bootimg | sed "s/ //g")
        cmd_line=$($bb od -A n -S1 -j 44 -N 1536 $bootimg)
        os_version=$($bb od -A n -D -j 16 -N 4 $bootimg | sed "s/ //g")
	patch_level=$(($os_version & ((1<<11) - 1)))
        os_version=$(($os_version>>11))
        os_version=$(($os_version>>14)).$(($os_version>>7 & ((1<<7) - 1))).$(($os_version & ((1<<7) - 1)))
        patch_level=$((($patch_level>>4) + 2000)):$(($patch_level & ((1<<4) - 1)))
    fi
fi
base_addr=$((kernel_addr-0x00008000))
kernel_offset=$((kernel_addr-base_addr))
ramdisk_offset=$((ramdisk_addr-base_addr))
second_offset=$((second_addr-base_addr))
tags_offset=$((tags_addr-base_addr))
dtbo_offset=$((dtbo_addr-base_addr))
dtb_offset=$((dtb_addr-base_addr))
base_addr=$(printf "%08x" $base_addr)
kernel_offset=$(printf "%08x" $kernel_offset)
ramdisk_offset=$(printf "%08x" $ramdisk_offset)
second_offset=$(printf "%08x" $second_offset)
tags_offset=$(printf "%08x" $tags_offset)
dtbo_offset=$(printf "%08x" $dtbo_offset)
dtb_offset=$(printf "%08x" $dtb_offset)
base_addr=0x${base_addr:0-8}
kernel_offset=0x${kernel_offset:0-8}
ramdisk_offset=0x${ramdisk_offset:0-8}
second_offset=0x${second_offset:0-8}
tags_offset=0x${tags_offset:0-8}
dtbo_offset=0x${dtbo_offset:0-8}
dtb_offset=0x${dtb_offset:0-8}

if [ $version -gt 2 ] && [ "$VNDRBOOT" == "false" ]; then
    tags_offset=
    ramdisk_offset=
elif [ "$VNDRBOOT" == "true" ]; then
    kernel=
    dtbo_offset=
fi

k_count=$(((kernel_size+page_size-1)/page_size))
r_count=$(((ramdisk_size+page_size-1)/page_size))
s_count=$(((second_size+page_size-1)/page_size))
d_count=$(((dtb_size+page_size-1)/page_size))
do_count=$(((dtbo_size+page_size-1)/page_size))

k_offset=1
r_offset=$((k_offset+k_count))
s_offset=$((r_offset+r_count))
do_offset=$((s_offset+s_count))
d_offset=$((do_offset+do_count))
#kernel
dd if=$bootimg of=kernel_tmp bs=$page_size skip=$k_offset count=$k_count 2>/dev/null
dd if=kernel_tmp of=kernel bs=$kernel_size count=1 2>/dev/null
#ramdisk.packed
dd if=$bootimg of=ramdisk_tmp bs=$page_size skip=$r_offset count=$r_count 2>/dev/null
dd if=ramdisk_tmp of=ramdisk.packed bs=$ramdisk_size count=1 2>/dev/null
#second
if [ $second_size -gt 0 ]; then
   dd if=$bootimg of=second.img.tmp bs=$page_size skip=$s_offset count=$s_count 2>/dev/null
   dd if=second.img.tmp of=second.img bs=$second_size count=1 2>/dev/null
   s_name="second=second.img\n"
   s_size="second_size=$second_size\n"
fi
#dtb
if [ $dtb_size -gt 0 ]; then
    dd if=$bootimg of=dt.img_tmp bs=$page_size skip=$d_offset count=$d_count 2>/dev/null
    dd if=dt.img_tmp of=dt.img bs=$dtb_size count=1 2>/dev/null
    dt="$tempdir/dt.img"
    dt=$(basename $dt)
    dt_size="dtb_size=$dtb_size\n"
    [ $version -gt 1 ] && dt=dtb.img && mv $tempdir/dt.img $tempdir/dtb.img &&\
        dt_size="dtb_offset=${dtb_offset}\n"${dt_size}
    dt_name="dt=$dt\n"
fi
#dtbo
if [ $dtbo_size -gt 0 ]; then
    dd if=$bootimg of=dtbo.img_tmp bs=$page_size skip=$do_offset count=$do_count 2>/dev/null
    dd if=dtbo.img_tmp of=dtbo.img bs=$dtbo_size count=1 2>/dev/null
    dtbo="$tempdir/dtbo.img"
    dtbo=$(basename $dtbo)
    do_name="dtbo=$dtbo\n"
fi
rm -f *_tmp $(basename $1) $bootimg

kernel=kernel
ramdisk=ramdisk
[ "$VNDRBOOT" == "false" ] && [ ! -s $kernel ] && exit

# Print boot.img/recovery.img info
[ ! -z "$board" ] && pout "  board               : $board"
[ $version -lt 3 ] || [ "$VNDRBOOT" == "false" ] && \
	pout "  kernel              : $kernel"
pout "  ramdisk             : $ramdisk"
pout "  page size           : $page_size"
[ $version -lt 3 ] || [ "$VNDRBOOT" == "false" ] && \
	pout "  kernel size         : $kernel_size" && \
	pout "  ramdisk size        : $ramdisk_size"
[ ! -z $second_size ] && [ $second_size -gt 0 ] && \
	pout "  second_size         : $second_size"
pout "  base                : $base_addr"
[ $version -lt 3 ] || [ "$VNDRBOOT" == "true" ] && \
	pout "  kernel offset       : $kernel_offset" && \
	pout "  ramdisk offset      : $ramdisk_offset"
[ $version -gt 0 ] && [ $dtbo_size -gt 0 ] && pout "  boot header version : $version" && \
	pout "  dtbo                : $dtbo" && \
	pout "  dtbo size           : $dtbo_size" && \
	pout "  dtbo offset         : $dtbo_offset"
[ $dtb_size -gt 0 ] && pout "  dtb img             : $dt" && \
	pout "  dtb size            : $dtb_size"
[ $version -gt 1 ] && [ "$VNDRBOOT" == "true" ] && \
	pout "  dtb offset          : $dtb_offset"
[ ! -z $second_size ] && [ $second_size -gt 0 ] && \
	pout "  second_offset       : $second_offset"
[ ! -z $os_version ] || [ ! -z $patch_level ] && \
	pout "  os_version          : $os_version" && \
	pout "  os_patch_level      : $patch_level" && \
	os_data="os_version=$os_version\nos_patch_level=$patch_level\n"
pout "  tags offset         : $tags_offset"
pout "  cmd line            : $cmd_line"

esq="'\"'\"'"
escaped_cmd_line=$(echo $cmd_line | sed "s/'/$esq/g")

# Write info to img_info, decompress ramdisk.packed
printf "kernel=kernel\nramdisk=ramdisk\n${s_name}page_size=$page_size\n${do_name}${dt_name}\
kernel_size=$kernel_size\nramdisk_size=$ramdisk_size\n${s_size}${dt_size}base_addr=$base_addr\nkernel_offset=$kernel_offset\n\
ramdisk_offset=$ramdisk_offset\ntags_offset=$tags_offset\ndtbo_offset=$dtbo_offset\n${os_data}cmd_line=\'$escaped_cmd_line\'\nboard=\"$board\"\n" > img_info

# MTK ramdisk (MTK Header Size 512, MAGIC 0x58881688)
mtk_header_magic="58881688"
ramdisk_packed_header=$($bb od -A n -X -j 0 -N 4 ramdisk.packed | sed 's/ //g')
if [ $ramdisk_packed_header = $mtk_header_magic ]; then
    mv ramdisk.packed ramdisk.packed.mtk
    dd if=ramdisk.packed.mtk of=ramdisk.packed ibs=512 skip=1 2>/dev/null
    dd if=ramdisk.packed.mtk of=ramdisk.mtk_header bs=512 count=1 2>/dev/null
    partition_size=$($bb od -A n -D -j 4 -N 4 ramdisk.packed.mtk | sed 's/ //g')
    partition_name=$($bb od -A n -S1 -j 8 -N 32 ramdisk.packed.mtk)
    escaped_partition_name=$(echo $partition_name | sed "s/'/$esq/g")
    printf "ramdisk has a MTK header:\n\tpartition_size=${partition_size}\n\tpartition_name=$escaped_partition_name\n" >> img_info
    pout "  ramdisk has a MTK header"
    pout "    header_size : 512"
    pout "    partition_size : $partition_size"
    pout "    partition_name : $escaped_partition_name"
    rm -f ramdisk.packed.mtk
fi

mkdir ramdisk && cd ramdisk

if $bb gzip -t ../ramdisk.packed 2>/dev/null; then
    pout "ramdisk is gzip format."
    format=gzip
    $bb gzip -d -c ../ramdisk.packed | cpio -i -d -m --no-absolute-filenames 2>/dev/null
    unpack_complete
fi
if $bb lzma -t ../ramdisk.packed 2>/dev/null; then
    pout "ramdisk is lzma format."
    format=lzma
    $bb lzma -d -c ../ramdisk.packed | cpio -i -d -m --no-absolute-filenames 2>/dev/null
    unpack_complete
fi
if $bb xz -t ../ramdisk.packed 2>/dev/null; then
    pout "ramdisk is xz format."
    format=xz
    $bb xz -d -c ../ramdisk.packed | cpio -i -d -m --no-absolute-filenames 2>/dev/null
    unpack_complete
fi
if $bb lzop -t ../ramdisk.packed 2>/dev/null; then
    pout "ramdisk is lzo format."
    format=lzop
    $bb lzop -d -c ../ramdisk.packed | cpio -i -d -m --no-absolute-filenames 2>/dev/null
    unpack_complete
fi
if lz4 -d ../ramdisk.packed 2>/dev/null | cpio -i -d -m --no-absolute-filenames 2>/dev/null; then
    pout "ramdisk is lz4 format."
    format=lz4
else
    pout "ramdisk is unknown format,can't unpack ramdisk"
fi
unpack_complete
