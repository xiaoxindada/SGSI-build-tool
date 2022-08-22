#!/bin/bash

LOCALDIR=`cd "$( dirname $0 )" && pwd`
cd $LOCALDIR

systemdir=$1

rm -rf $1/MzApp/*
rm -rf $1/product/custom/*

apps_dir="
AlwaysOnDisplay
FlymeAlarmClock
MzUpdate
WPS_Meizu_Version
DataMigration
Email
Life
PerfUI
Reader
RemoteCooperation
VideoClips
DesktopBackup
FamilyGuard
GmsCore
Phonesky_CN
Browser
DirectService
EasyLauncher
FlymeGallery
FlymeLab
FlymeMusic
FlymeSoundRecorder
MeizuPay
PhotoService
Search
Video
"
for delete_dir in $apps_dir ;do
  find $systemdir -type d -name "$delete_dir" | xargs rm -rf
done
