#!/bin/bash

LOCALDIR=$(cd "$(dirname ${BASH_SOURCE[0]})" && pwd)
cd $LOCALDIR

export LD_LIBRARY=$LOCALDIR/lib64
lpdump="$LOCALDIR/lpdump"

usage() {
    echo "usage:"
    echo "$0 <super.img>"
    exit 1
}

if [ $# -ne 1 ]; then
    usage
fi

$lpdump $1 >super_info.txt
