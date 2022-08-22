#!/bin/bash

LOCALDIR=`cd "$( dirname $0 )" && pwd`
cd $LOCALDIR

systemdir="../out/system/system"
configdir="../out/config"
bin="../bin"

cp -frp ./vivo/system/* $systemdir