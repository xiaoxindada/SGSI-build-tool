#!/bin/bash

LOCALDIR=$(cd "$(dirname ${BASH_SOURCE[0]})" && pwd)
cd $LOCALDIR
source ./bin.sh
source ./language_helper.sh

mkdir -p ./SGSI
cp -frp ./other/* ./SGSI/
for i in Patch{1..3}; do
  if [ -d ./SGSI/$i ]; then
    cd ./SGSI/$i
    echo "$GENERATRING_STR $i"
    zip -r ../$i.zip ./* 2 &>/dev/null
    cd $LOCALDIR
    rm -rf ./SGSI/$i
  fi
done

echo "$GENERATRING_STR Vbmeta_Patch"
#$bin/apex_tools/avbtool.py make_vbmeta_image --set_hashtree_disabled_flag --flags 2 --padding_size 4096 --output ./SGSI/Vbmeta_Patch/vbmeta_disabled.img
cd ./SGSI/Vbmeta_Patch
zip -r ../Vbmeta_Patch.zip ./* 2 &>/dev/null
cd $LOCALDIR
rm -rf ./SGSI/Vbmeta_Patch

echo "$GENERATRING_STR vendor_boot_patch"
cd ./SGSI/vendor_boot_patch
zip -r ../vendor_boot_patch.zip ./* 2 &>/dev/null
cd $LOCALDIR
rm -rf ./SGSI/vendor_boot_patch

chmod 777 -R ./SGSI
