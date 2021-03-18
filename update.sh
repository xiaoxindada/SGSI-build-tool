#!/bin/bash

LOCALDIR=`cd "$( dirname $0 )" && pwd`
cd $LOCALDIR

git submodule update --init --recursive
git pull --recurse-submodules

