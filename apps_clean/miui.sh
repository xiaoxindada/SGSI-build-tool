#!/bin/bash

LOCALDIR=`cd "$( dirname $0 )" && pwd`
cd $LOCALDIR

rm -rf $1/data-app/*

rm -rf $1/app/Cit
rm -rf $1/app/HybridPlatform
rm -rf $1/app/GFTest
rm -rf $1/app/MiuiBugReport
rm -rf $1/app/VoiceAssist
rm -rf $1/priv-app/MiuiVideo
rm -rf $1/priv-app/Music
rm -rf $1/app/Music
rm -rf $1/priv-app/QuickSearchBox
rm -rf $1/priv-app/MiService
rm -rf $1/priv-app/MiGameCenterSDKService
rm -rf $1/app/Mipay
rm -rf $1/app/MiLinkService2
rm -rf $1/app/DeskClock
rm -rf $1/app/Cit
rm -rf $1/product/app/aiasst_service
rm -rf $1/product/app/talkback
#rm -rf $1/product/priv-app/GmsCore
rm -rf $1/product/priv-app/GooglePlayServicesUpdater
rm -rf $1/priv-app/Browser
rm -rf $1/priv-app/Backup
rm -rf $1/priv-app/CloudBackup
rm -rf $1/priv-app/Mirror
rm -rf $1/priv-app/MiService
rm -rf $1/priv-app/MiuiGallery