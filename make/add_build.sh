#!/bin/bash

LOCALDIR=`cd "$( dirname $0 )" && pwd`
cd $LOCALDIR

# oem属性添加
sed -i '/#end/d' ../out/vendor/build.prop
echo "#end" >> ../out/vendor/build.prop
start=$((`grep -n '# ADDITIONAL VENDOR BUILD PROPERTIES' ../out/vendor/build.prop | cut -d ":" -f 1`+2))
end=$((`grep -n '#end' ../out/vendor/build.prop | sed 's/:#end//g' `-1))
sed -n ${start},${end}p ../out/vendor/build.prop > ./oem.txt
sed -i '/ro.control_privapp_permissions/d' ./oem.txt
sed -i '/debug.sf/d' ./oem.txt
sed -i '/vendor.display/d' ./oem.txt
sed -i '/sys.haptic/d' ./oem.txt
sed -i '/hbm/d' ./oem.txt
sed -i '/ro.oem_unlock.pst/d' ./oem.txt
sed -i '/ro.frp.pst/d' ./oem.txt
sed -i '/ro.build.expect/d' ./oem.txt
sed -i '/ro.sf.lcd_density/d' ./oem.txt
sed -i '/ro.apex.updatable/d' ./oem.txt
sed -i '/vendor.audio/d' ./oem.txt
sed -i '/log/d' ./oem.txt
sed -i '/opengles.version/d' ./oem.txt
sed -i '/vendor.perf/d' ./oem.txt
sed -i '/vendor.media/d' ./oem.txt
sed -i '/debug.media/d' ./oem.txt
sed -i '/ro.telephony.iwlan_operation_mode/d' ./oem.txt

sed -i '/^\s*$/d' ./oem.txt
cat ./oem.txt >> ./add_build/add_oem_build
rm -rf ./oem.txt

