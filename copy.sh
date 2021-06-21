#!/bin/bash

LOCALDIR=`cd "$( dirname $0 )" && pwd`
cd $LOCALDIR

cp -frp ./other/* ./SGSI/
chmod 777 -R ./SGSI
