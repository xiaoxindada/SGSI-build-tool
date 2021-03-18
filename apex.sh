#!/bin/bash

LOCALDIR=`cd "$( dirname $0 )" && pwd`
cd $LOCALDIR
source ./bin.sh

cd $bin/apex_unpack
./unpackapex.sh
