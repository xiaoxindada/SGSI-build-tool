#!/bin/sh

LOCALDIR=`cd "$( dirname $0 )" && pwd`
cd $LOCALDIR

rm -rf ./system
mkdir -p ./system/framework
chmod 777 -R ./system
