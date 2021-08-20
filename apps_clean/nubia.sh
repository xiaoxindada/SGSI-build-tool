LOCALDIR=`cd "$( dirname ${BASH_SOURCE[0]} )" && pwd`
cd $LOCALDIR

rm -rf ./preset_apps
mkdir ./preset_apps
apps=$(find $1 -type d -name 'preset_apps') && nubia_app=$(find ${apps} -type d -name "nubia_*")
for i in ${nubia_app};do
  mv $i ./preset_apps/
done
rm -rf $apps
mv ./preset_apps $1
