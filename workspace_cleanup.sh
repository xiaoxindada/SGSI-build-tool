#!/bin/bash

LOCALDIR=`cd "$( dirname ${BASH_SOURCE[0]} )" && pwd`
cd $LOCALDIR
source ./language_helper.sh

mkdir -p ./tmp
echo $CLEANINGWORKSPACE_STR
if [ -e ./tmp/*.bin ];then
  rm -rf ./tmp/*.bin
fi

if [ -e ./tmp/*.zip ];then
  mv ./tmp/*.zip ./
  rm -rf ./compatibility.zip
  rm -rf ./tmp/*
  mv ./*.zip ./tmp/
fi
