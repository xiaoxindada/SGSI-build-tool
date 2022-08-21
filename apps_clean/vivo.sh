#!/bin/bash

LOCALDIR=`cd "$( dirname $0 )" && pwd`
cd $LOCALDIR

systemdir=$1

apps_dir="
BBKCloud
BBKCrontab
BBKMusic
BBKTimer
FamilyCareLocal
GlobalAnimation
GlobalSearch
HiBoard
HybridPlatform
MagazineService
PenWrite
talkback
UpnpServer
VideoPlayer
VivoAssistant
VivoCalendar
VivoCamera
VivoGallery
vivospace-v2
VivoTws
VoiceWakeup
VTouch
AiTranslate
BBKCalculator
BBKNotes
BBKSoundRecorder
BBKWeather
ChildrenMode
Compass
DoubleTimezoneClock
FamilyCare
Feedback
Firenze
iReader
NewsReader
VideoEditor
vivogame
VivoTips
VivoShare
UpnpServer
Email
vivoOffice
iRoaming
iRoamingService
vivoWallet
BuiltInPrintService
VLife_vivo
Updater
EasyShare
AiAgent
Baidu
IoTSmartLife
JoviIme
VivoBrowser
GmsCore
GooglePlayServicesUpdater
"
for delete_dir in $apps_dir ;do
  find $systemdir -type d -name "$delete_dir" | xargs rm -rf
done

rm -rf $systemdir/build-in-app/VHome.apk

# Google gms精简需要的prop属性
sed -i '/ro.com.google.gmsversion/d' $systemdir/product/build.prop

media_dir="$systemdir/media"
delete_files=$(find $media_dir -maxdepth 1 -type f -name "*" | grep -v "bootanimation.zip")
rm -rf $delete_files
