LOCALDIR=`cd "$( dirname $0 )" && pwd`
cd $LOCALDIR

rm -rf ./preset_apps
mkdir ./preset_apps
apps=$(find $1 -type d -name 'preset_apps') && nubia_app=$(find ${apps} -type d -name "nubia_*")
for i in ${nubia_app};do
  mv $i ./preset_apps/
done
rm -rf $apps
mv ./preset_apps $1
rm -rf $1/app/AutoAgingTest
rm -rf $1/app/FactoryTestAdvanced
rm -rf $1/app/GFDelmarProductTest
rm -rf $1/app/nubia_Browser
rm -rf $1/app/nubia_DeskClock
rm -rf $1/app/nubia_DynamicWallpaper*
rm -rf $1/app/nubia_GameHighlights
rm -rf $1/app/nubia_GameLauncher
rm -rf $1/app/nubia_NeoHybrid
rm -rf $1/app/redtea_cos
#rm -rf $1/app/TP_SogouInput_nubia
rm -rf $1/app/TP_YulorePage_v1.0.0
rm -rf $1/priv-app/AOD*
rm -rf $1/priv-app/Camera
rm -rf $1/priv-app/NBGalleryLockScreen
rm -rf $1/priv-app/nubia_HaloVoice
rm -rf $1/priv-app/nubia_touping
rm -rf $1/priv-app/NubiaGallery
rm -rf $1/priv-app/NubiaVideo
rm -rf $1/priv-app/PhotoEditor
rm -rf $1/priv-app/TXSearchBox
rm -rf $1/product/priv-app/ConfigUpdater
rm -rf $1/product/priv-app/GmsCore
rm -rf $1/product/priv-app/GooglePartnerSetup
rm -rf $1/product/priv-app/GooglePlayServicesUpdater
