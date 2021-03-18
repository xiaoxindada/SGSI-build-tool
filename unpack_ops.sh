#!/bin/bash

LOCALDIR=`cd "$( dirname $0 )" && pwd`
cd $LOCALDIR
source ./bin.sh

Usage() {
cat <<EOT
Usage:
$0 <Ops File Path> <Out Dir>
EOT
}

if [ $# -le 1 ];then
  Usage
	exit
fi

oppo_extract_tooldir="$bin/oppo_decrypt"
ops_extract_tool="$oppo_extract_tooldir/opscrypto.py"
ops_file="$1"
outdir="$2"
[ -z "$outdir" ] && outdir="out"

if [[ -e $ops_file ]]; then
	printf "Decrypting ops & extracing...\n"
	python3 "${ops_extract_tool}" decrypt "${ops_file}" "${outdir}"
fi
