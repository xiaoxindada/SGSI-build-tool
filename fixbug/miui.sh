#!/bin/bash

xml="$(find ../out/system/ -type d -name 'device_features')" && device="$(find $xml -name '*.xml')"
 
# Disable round corner
sed -i 's/support_round_corner">true/support_round_corner">false/g' $device

# Fix theme
sed -i 's#chmod 0775 /data/system/theme#chmod 0777 /data/system/theme#g' ../out/system/init.miui.rc
sed -i 's#chmod 0775 /data/system/theme/lock_wallpaper#chmod 0777 /data/system/theme/lock_wallpaper#g' ../out/system/init.miui.rc
sed -i 's#chmod 0775 /data/system/theme_magic#chmod 0777 /data/system/theme_magic#g' ../out/system/init.miui.rc
sed -i 's#chmod 0775 /data/system/theme_magic/customized_icons#chmod 0777 /data/system/theme_magic/customized_icons#g' ../out/system/init.miui.rc
sed -i 's/0775 theme/0777 theme/g' ../out/system/init.miui.rc

#cp -frp ./miui/system/* ../out/system/system/

# Fix statusbar flashlight
Flashlight_fix (){
 xml="$(find ../out/system/ -type d -name 'device_features')" && Flashlight="$(find $xml -name '*.xml')"
 grep '<bool name="support_android_flashlight">true</bool>' $Flashlight > /dev/null 2>&1
}

if Flashlight_fix ;then
 echo ""  > /dev/null 2>&1
else
 sed -i '/<\/features>/d' $Flashlight
 cat ./miui/Flashlight.patch >> $Flashlight
 echo "</features>" >> $Flashlight
fi

# Remove pre-installed apps tip
auto="$(find ../out/system/ -name 'auto-install.json')"
true > $auto

# Decompile services
cp -frp $(find ../out/system -type f -name 'services.jar') ./miui/
cd ./miui
./decompile.sh
cd ../
