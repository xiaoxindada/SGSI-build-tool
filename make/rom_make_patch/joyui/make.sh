#!/bin/bash

LOCALDIR=`cd "$( dirname $0 )" && pwd`
cd $LOCALDIR

bin="$LOCALDIR/../../../tool_bin"
systemdir="$LOCALDIR/../../../out/system/system"
configdir="$LOCALDIR/../../../out/config"
toolsdir="$LOCALDIR/../../.."
tmpdir="$LOCALDIR/tmp"
outdir="$tmpdir/out"

rm -rf $tmpdir
mkdir -p $tmpdir
mkdir -p $outdir


# system patch 
cp -frp $LOCALDIR/system/* $systemdir
cat $LOCALDIR/contexts >> $configdir/system_file_contexts
cat $LOCALDIR/fs >> $configdir/system_fs_config

rm -rf $tmpdir
