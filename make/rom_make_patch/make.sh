#!/bin/bash

LOCALDIR=`cd "$( dirname $0 )" && pwd`
cd $LOCALDIR

WORKSPACE=$LOCALDIR/../../workspace
IMAGESDIR=$WORKSPACE/images
TARGETDIR=$WORKSPACE/out

configdir="$TARGETDIR/config"
systemdir="$TARGETDIR/system/system"

echo "rom修补处理中"
