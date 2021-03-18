#!/bin/bash

LOCALDIR=`cd "$( dirname $0 )" && pwd`
cd $LOCALDIR

systemdir=$1

apps_dir="
Email
OppoCamera
OppoEngineerCamera
Browser
#SogouInput
HeytapBook
BrowserVideo
OPPOStore
ColorFavorite
OppoNote2
OShare
SOSHelper
OPPOCommunity
OperationTips
KeKeUserCenter
OppoGallery2t
KeKePay
OppoGallery2
KeKeMarket
KeKeUserCenter
GooglePlayServicesUpdater
GmsCore
"
for delete_dir in $apps_dir ;do
  find $systemdir -type d -name "$delete_dir" | xargs rm -rf
done
