#!/bin/bash
#
# To call this script, make sure mkfs.erofs is somewhere in PATH

function usage() {
cat<<EOT
Usage:
$0 SRC_DIR OUTPUT_FILE [-s] [-m MOUNT_POINT] [-d PRODUCT_OUT] [-C FS_CONFIG ] [-c FILE_CONTEXTS] [-z COMPRESSOR] [-T TIMESTAMP] [-U UUID]
EOT
}

#echo "in mkerofsimage.sh PATH=$PATH"

LOCALDIR=`cd "$( dirname ${BASH_SOURCE[0]} )" && pwd`

if [ $# -lt 2 ]; then
    usage
    exit 1
fi

SRC_DIR=$1
if [ ! -d $SRC_DIR ]; then
  echo "Can not find directory $SRC_DIR!"
  exit 2
fi
OUTPUT_FILE=$2
shift; shift

SPARSE=false
if [[ "$1" == "-s" ]]; then
    SPARSE=true
    shift;
fi

MOUNT_POINT=
if [[ "$1" == "-m" ]]; then
    MOUNT_POINT=$2
    shift; shift
fi

PRODUCT_OUT=
if [[ "$1" == "-d" ]]; then
    PRODUCT_OUT=$2
    shift; shift
fi

FS_CONFIG=
if [[ "$1" == "-C" ]]; then
    FS_CONFIG=$2
    shift; shift
fi

FILE_CONTEXTS=
if [[ "$1" == "-c" ]]; then
    FILE_CONTEXTS=$2
    shift; shift
fi

COMPRESSOR="lz4"
if [[ "$1" == "-z" ]]; then
    COMPRESSOR=$2
    shift; shift
fi

TIMESTAMP=
if [[ "$1" == "-T" ]]; then
    TIMESTAMP=$2
    shift; shift
fi

UUID=
if [[ "$1" == "-U" ]]; then
    UUID=$2
    shift; shift
fi

OPT=""
if [ -n "$MOUNT_POINT" ]; then
  OPT="$OPT --mount-point $MOUNT_POINT"
fi
if [ -n "$PRODUCT_OUT" ]; then
  OPT="$OPT --product-out $PRODUCT_OUT"
fi
if [ -n "$FS_CONFIG" ]; then
  OPT="$OPT --fs-config-file $FS_CONFIG"
fi
if [ -n "$FILE_CONTEXTS" ]; then
  OPT="$OPT --file-contexts $FILE_CONTEXTS"
fi
if [ -n "$TIMESTAMP" ]; then
  OPT="$OPT -T $TIMESTAMP"
fi
if [ -n "$UUID" ]; then
  OPT="$OPT -U $UUID"
fi

mkfs_erofs="$LOCALDIR/mkfs.erofs"
img2simg="$LOCALDIR/img2simg"

MAKE_EROFS_CMD="$mkfs_erofs -z $COMPRESSOR $OPT $OUTPUT_FILE $SRC_DIR"
echo $MAKE_EROFS_CMD
$MAKE_EROFS_CMD

if [ $? -ne 0 ]; then
    exit 4
fi

SPARSE_SUFFIX=".sparse"
if [ "$SPARSE" = true ]; then
    $img2simg $OUTPUT_FILE $OUTPUT_FILE$SPARSE_SUFFIX
    if [ $? -ne 0 ]; then
        exit 4
    fi
    mv $OUTPUT_FILE$SPARSE_SUFFIX $OUTPUT_FILE
fi

