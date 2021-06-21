#!/bin/bash

LOCALDIR=`cd "$( dirname $0 )" && pwd`
cd $LOCALDIR

bin="$LOCALDIR/../../../bin"
toolsdir="$bin/.."
tmpdir="$LOCALDIR/tmp"
systemdir="$LOCALDIR/../../../out/system/system"
configdir="$LOCALDIR/../../../out/config"
oppo_brsdir="$LOCALDIR/tmp/oppo_brs"
oppo_imagesdir="$LOCALDIR/tmp/oppo_images"
oppo_images_outdir="$LOCALDIR/tmp/oppo_images_out"

rm -rf $tmpdir
mkdir -p $tmpdir
mkdir -p $oppo_brsdir
mkdir -p $oppo_imagesdir
mkdir -p $oppo_images_outdir

my_brs=$(find $systemdir/../../../tmp -type f -name "*" | grep "my_*")
for oppo_brs in $my_brs ;do
  mv $oppo_brs $oppo_brsdir
done

oppo_brs_name=$(ls $oppo_brsdir)
for oppo_brs in $oppo_brs_name ;do
  oppo_brs_modeify_name=$(echo "$oppo_brs" | tr -d "[0-9]" | sed 's/\.\./\./')
  if echo "$oppo_brs" | grep -q "[0-9]" ;then
    mv $oppo_brsdir/$oppo_brs $oppo_brsdir/$oppo_brs_modeify_name
  fi
done

oppo_partition_extract() {
  if [ -e $oppo_brsdir/my_carrier.new.dat.br ];then
    echo "正在解压my_carrier.new.dat.br"
    $bin/brotli -d $oppo_brsdir/my_carrier.new.dat.br
    $bin/sdat2img.py $oppo_brsdir/my_carrier.transfer.list $oppo_brsdir/my_carrier.new.dat $oppo_imagesdir/my_carrier.img > /dev/null 2>&1
  fi

  if [ -e $oppo_brsdir/my_company.new.dat.br ];then
    echo "正在解压my_company.new.dat.br"
    $bin/brotli -d $oppo_brsdir/my_company.new.dat.br
    $bin/sdat2img.py $oppo_brsdir/my_company.transfer.list $oppo_brsdir/my_company.new.dat $oppo_imagesdir/my_company.img > /dev/null 2>&1
  fi

  if [ -e $oppo_brsdir/my_engineering.new.dat.br ];then
    echo "正在解压my_engineering.new.dat.br"
   $bin/brotli -d $oppo_brsdir/my_engineering.new.dat.br
    $bin/sdat2img.py $oppo_brsdir/my_engineering.transfer.list $oppo_brsdir/my_engineering.new.dat $oppo_imagesdir/my_engineering.img > /dev/null 2>&1
  fi

  if [ -e $oppo_brsdir/my_heytap.new.dat.br ];then
    echo "正在解压my_heytap.new.dat.br"
    $bin/brotli -d $oppo_brsdir/my_heytap.new.dat.br
    $bin/sdat2img.py $oppo_brsdir/my_heytap.transfer.list $oppo_brsdir/my_heytap.new.dat $oppo_imagesdir/my_heytap.img > /dev/null 2>&1
  fi

  if [ -e $oppo_brsdir/my_manifest.new.dat.br ];then
    echo "正在解压my_manifest.new.dat.br"
    $bin/brotli -d $oppo_brsdir/my_manifest.new.dat.br
    $bin/sdat2img.py $oppo_brsdir/my_manifest.transfer.list $oppo_brsdir/my_manifest.new.dat $oppo_imagesdir/my_manifest.img > /dev/null 2>&1
  fi

  if [ -e $oppo_brsdir/my_preload.new.dat.br ];then
    echo "正在解压my_preload.new.dat.br"
    $bin/brotli -d $oppo_brsdir/my_preload.new.dat.br
    $bin/sdat2img.py $oppo_brsdir/my_preload.transfer.list $oppo_brsdir/my_preload.new.dat $oppo_imagesdir/my_preload.img > /dev/null 2>&1
  fi

  if [ -e $oppo_brsdir/my_product.new.dat.br ];then
    echo "正在解压my_product.new.dat.br"
    $bin/brotli -d $oppo_brsdir/my_product.new.dat.br
    $bin/sdat2img.py $oppo_brsdir/my_product.transfer.list $oppo_brsdir/my_product.new.dat $oppo_imagesdir/my_product.img > /dev/null 2>&1
  fi

  if [ -e $oppo_brsdir/my_region.new.dat.br ];then
    echo "正在解压my_region.new.dat.br"
    $bin/brotli -d $oppo_brsdir/my_region.new.dat.br
    $bin/sdat2img.py $oppo_brsdir/my_region.transfer.list $oppo_brsdir/my_region.new.dat $oppo_imagesdir/my_region.img > /dev/null 2>&1
  fi

  if [ -e $oppo_brsdir/my_stock.new.dat.br ];then
    echo "正在解压my_stock.new.dat.br"
    $bin/brotli -d $oppo_brsdir/my_stock.new.dat.br
    $bin/sdat2img.py $oppo_brsdir/my_stock.transfer.list $oppo_brsdir/my_stock.new.dat $oppo_imagesdir/my_stock.img > /dev/null 2>&1
  fi 
 
  system_euclid_dir=""
  vendor_euclid_dir=""
  if [[ -e $systemdir/euclid && -d $systemdir/euclid ]];then
    system_euclid_dir+="$systemdir/euclid" 
  fi  
  if [[ -e $toolsdir/out/vendor/euclid  && -d $toolsdir/out/vendor/euclid ]];then
    vendor_euclid_dir+="$toolsdir/out/vendor/euclid" 
  fi 
  br_file_number=`(cd $oppo_brsdir && ls) | (wc -l && cd $LOCALDIR)`
  if [ $br_file_number = "0" ];then
    system_euclid_images_name=$(ls $system_euclid_dir)
    for euclid_images in $system_euclid_images_name ;do
      if echo "$euclid_images" | grep -q "[0-9]" ;then
        mv $system_euclid_dir/$euclid_images $system_euclid_dir/$(echo "$euclid_images" | tr -d "[0-9]" | sed 's/\.\./\./')
      fi
      echo ""
      echo "正在复制 $system_euclid_dir/$euclid_images 至 $oppo_imagesdir"
      cp -frp $system_euclid_dir/$euclid_images $oppo_imagesdir
      rm -rf $system_euclid_dir/$euclid_images 
    done

    vendor_euclid_images_name=$(ls $vendor_euclid_dir)
    for euclid_images in $vendor_euclid_images_name ;do
      if echo "$euclid_images" | grep -q "[0-9]" ;then
        mv $vendor_euclid_dir/$euclid_images $vendor_euclid_dir/$(echo "$euclid_images" | tr -d "[0-9]" | sed 's/\.\./\./')
      fi
      echo ""  
      echo "正在复制 $vendor_euclid_dir/$euclid_images 至 $oppo_imagesdir"
      cp -frp $vendor_euclid_dir/$euclid_images $oppo_imagesdir
      rm -rf $vendor_euclid_dir/$euclid_images 
    done  
  fi  

  if [ -e $oppo_imagesdir/my_carrier.img ];then
    python3 $bin/imgextractor.py $oppo_imagesdir/my_carrier.img $oppo_images_outdir > /dev/null 2>&1
  fi  

  if [ -e $oppo_imagesdir/my_company.img ];then
    python3 $bin/imgextractor.py $oppo_imagesdir/my_company.img $oppo_images_outdir > /dev/null 2>&1
  fi

  if [ -e $oppo_imagesdir/my_engineering.img ];then
    python3 $bin/imgextractor.py $oppo_imagesdir/my_engineering.img $oppo_images_outdir > /dev/null 2>&1
  fi

  if [ -e $oppo_imagesdir/my_heytap.img ];then
    python3 $bin/imgextractor.py $oppo_imagesdir/my_heytap.img $oppo_images_outdir > /dev/null 2>&1
  fi  

  if [ -e $oppo_imagesdir/my_manifest.img ];then
    python3 $bin/imgextractor.py $oppo_imagesdir/my_manifest.img $oppo_images_outdir > /dev/null 2>&1
  fi  

  if [ -e $oppo_imagesdir/my_preload.img ];then
    python3 $bin/imgextractor.py $oppo_imagesdir/my_preload.img $oppo_images_outdir > /dev/null 2>&1
  fi

  if [ -e $oppo_imagesdir/my_product.img ];then
    python3 $bin/imgextractor.py $oppo_imagesdir/my_product.img $oppo_images_outdir > /dev/null 2>&1
  fi

  if [ -e $oppo_imagesdir/my_region.img ];then
    python3 $bin/imgextractor.py $oppo_imagesdir/my_region.img $oppo_images_outdir > /dev/null 2>&1
  fi  

  if [ -e $oppo_imagesdir/my_stock.img ];then
    python3 $bin/imgextractor.py $oppo_imagesdir/my_stock.img $oppo_images_outdir > /dev/null 2>&1
  fi  
}
oppo_partition_extract

merge_partition() {
  echo "正在合并oppo专有分区"
  oppo_configdir="$oppo_images_outdir/config"
  if [ -e $oppo_configdir ];then
    cp -fr $oppo_configdir $tmpdir
    rm -rf $oppo_configdir
  fi
  find $oppo_images_outdir -type d -name "lost+found" | xargs rm -rf

  oppo_partition_name_dir="$systemdir/.."
  oppo_merge_partition_name=$(ls $oppo_images_outdir)

  for oppo_partition_name in $oppo_merge_partition_name ;do
    rm -rf $oppo_partition_name_dir/$oppo_partition_name
  done

  for oppo_merge_partition in $oppo_merge_partition_name ;do
    mv $oppo_images_outdir/$oppo_merge_partition $oppo_partition_name_dir
  done
  echo "分区合并完成"
}
merge_partition

# oppo专有分区fs数据整合
config_name=$(ls $tmpdir/config)
for configs in $config_name ;do
  if [ $(echo "$configs" | grep "config$") ];then
    sed -i '1d' $tmpdir/config/$configs 
    sed -i 's/^/&system\//g' $tmpdir/config/$configs 
    cat $tmpdir/config/$configs >> $tmpdir/config/oppo_fs
  fi
  if [ $(echo "$configs" | grep "contexts$") ];then
    sed -i '1d' $tmpdir/config/$configs 
    sed -i '/\?/d' $tmpdir/config/$configs 
    sed -i 's/^/&\/system/g' $tmpdir/config/$configs
    cat $tmpdir/config/$configs >> $tmpdir/config/oppo_contexts
  fi  
done
cat $tmpdir/config/oppo_contexts >> $configdir/system_file_contexts
cat $tmpdir/config/oppo_fs >> $configdir/system_fs_config

oppo_odm_patch() {
  odm_out_dir="$tmpdir/oppo_odm_out"

  rm -rf $odm_out_dir
  rm -rf $tmpdir/system_ext
  mkdir -p $odm_out_dir
  mkdir -p $tmpdir/system_ext
  mkdir -p $tmpdir/system_ext/framework
  mkdir -p $tmpdir/system_ext/etc/permissions
  
  if [ -e $oppo_imagesdir/odm.img ];then
    mv $oppo_imagesdir/odm.img $tmpdir
  else
    mv $toolsdir/odm.img $tmpdir
  fi
  echo "正在提取odm分区"
  python3 $bin/imgextractor.py $tmpdir/odm.img $odm_out_dir > /dev/null 2>&1

  odmdir="$odm_out_dir/odm"
  framework_dir="$odmdir/framework"
  permissions_dir="$odmdir/etc/permissions"
  jar_files=$(find $framework_dir -maxdepth 1 -type f -name "*" | grep ".jar$" | grep "oplus")
  permissions_files=$(find $permissions_dir -maxdepth 1 -type f -name "*" | grep ".xml$" | grep "oplus")
  
  for oppo_jars in $jar_files ;do
    cp -frp $oppo_jars $tmpdir/system_ext/framework/
  done
  rm -rf $tmpdir/system_ext/framework/*"ufsplus"*

  for oppo_permissions in $permissions_files ;do 
    cp -frp $oppo_permissions $tmpdir/system_ext/etc/permissions/
  done
  rm -rf $tmpdir/system_ext/etc/permissions/*"ufsplus"*
  
  if [ ! $(find $odmdir -type f -name "orms_core_config.xml") = "" ];then
    cp -frp $(find $odmdir -type f -name "orms_core_config.xml") $tmpdir/system_ext/etc/permissions/
  fi

  if [ ! $(find $odmdir -type f -name "orms_permission_config.xml") = "" ];then
    cp -frp $(find $odmdir -type f -name "orms_permission_config.xml") $tmpdir/system_ext/etc/permissions/
  fi

  number=`(cd $tmpdir/system_ext/etc/permissions && ls) | (wc -l && cd $LOCALDIR)`
  if [ $number != "0" ];then
    permissions_files=$(ls $tmpdir/system_ext/etc/permissions)
    for patch_files in $permissions_files ;do
      sed -i "s#/odm/#/system/system_ext/#g" $tmpdir/system_ext/etc/permissions/$patch_files
    done
  fi

  # build合并
  sed -i '/import/d' $odmdir/build.prop
  echo "" >> $systemdir/build.prop
  cat $odmdir/build.prop >> $systemdir/build.prop

  filedir="$tmpdir/system_ext"
  cd $filedir
  file_name=$(find ./ -name "*" | sed '1d' | sed '1d')
  for file_fs in $file_name ;do
    echo "$file_fs" | sed 's#\./#/#g' | sed 's/^/&\/system\/system\/system_ext/g' | sed 's/$/& u:object_r:system_file:s0/g' >> $tmpdir/system_ext_contexts
    if [ -d "$file_fs" ];then
      echo "$file_fs" | sed 's#\./#/#g' | sed 's/^/&\/system\/system\/system_ext/g' | sed 's/$/& 0 0 0755/g' >> $tmpdir/system_ext_fs
    fi  
    if [ -f "$file_fs" ];then
      echo "$file_fs" | sed 's#\./#/#g' | sed 's/^/&\/system\/system\/system_ext/g' | sed 's/$/& 0 0 0644/g' >> $tmpdir/system_ext_fs
    fi  
  done
  cd $LOCALDIR

  cat $tmpdir/system_ext_contexts >> $configdir/system_file_contexts
  cat $tmpdir/system_ext_fs >> $configdir/system_fs_config
  cp -frp $tmpdir/system_ext/* $systemdir/system_ext/
}
if [ -e $toolsdir/odm.img ] || [ -e $oppo_imagesdir/odm.img ];then
  oppo_odm_patch
fi

# build修改
build_modify() {
  # system_ext build清理
  cp -frp $systemdir/system_ext/build.prop $tmpdir
  chmod 777 $tmpdir/build.prop
  sed -i "/#end/d" $tmpdir/build.prop
  echo "#end" >> $tmpdir/build.prop
  master_date=$(cat $tmpdir/build.prop | grep "ro.build.master.date" | cut -d "=" -f 2)
  sed -i "/ro.build.master.date\=$master_date/,/#end/d" $tmpdir/build.prop
  echo "ro.build.master.date=$master_date" >> $tmpdir/build.prop
  cat $LOCALDIR/add_system_ext_build >> $tmpdir/build.prop
  cp -frp $tmpdir/build.prop $systemdir/system_ext/build.prop

  # oppo专有分区build属性清理
  oppo_build_name=$(find $systemdir/../ -type f -name "build.prop")
  for oppo_builds in $oppo_build_name ;do
    if [ -e $oppo_builds ];then
      sed -i '/ro.sf.lcd/d' $oppo_builds
      sed -i '/ro.display.brightness/d' $oppo_builds
    fi
  done

  # import oppo custom build.prop
  if [ -e $systemdir/../my_product/build.prop ];then
    echo "import /my_product/build.prop" >> $systemdir/../my_product/build.prop
  fi

  # oppo custom build.prop merge
  if [ -e $systemdir/../my_manifest/build.prop ];then
    sed -i "/security_patch\=/d" $systemdir/../my_manifest/build.prop
    echo "" >> $systemdir/build.prop
    cat $systemdir/../my_manifest/build.prop >> $systemdir/build.prop
    true > $systemdir/../my_manifest/build.prop
  fi
  
  # 添加oppo专有分区路径
  echo "
# oppo custom partition path
ro.oppo.my_custom_root=/my_custom
ro.oppo.my_special_preload_root=/special_preload
ro.oppo.my_carrier_root=/my_carrier
ro.oppo.my_region_root=/my_region
ro.oppo.my_company_root=/my_company
ro.oppo.my_engineer_root=/my_engineering
ro.oppo.my_engineering_root=/my_engineering
ro.oppo.my_product_root=/my_product
ro.oppo.my_version_root=/my_version
ro.oppo.my_operator_root=/my_carrier
ro.oppo.my_country_root=/my_region
#ro.oppo.my_odm_root=/odm
ro.oppo.my_preload_root=/my_preload
ro.oppo.my_heytap_root=/my_heytap
ro.oppo.my_stock_root=/my_stock
ro.oppo.oppo_custom_root=/my_company
ro.oppo.oppo_engineer_root=/my_engineering
ro.oppo.oppo_product_root=/my_product
ro.oppo.oppo_version_root=/my_version
ro.oppo.my_manifest_root=/my_manifest   
  " >> $systemdir/build.prop

  echo "
# oppo custom partition path
ro.oppo.my_custom_root=/my_custom
ro.oppo.my_special_preload_root=/special_preload
ro.oppo.my_carrier_root=/my_carrier
ro.oppo.my_region_root=/my_region
ro.oppo.my_company_root=/my_company
ro.oppo.my_engineer_root=/my_engineering
ro.oppo.my_engineering_root=/my_engineering
ro.oppo.my_product_root=/my_product
ro.oppo.my_version_root=/my_version
ro.oppo.my_operator_root=/my_carrier
ro.oppo.my_country_root=/my_region
#ro.oppo.my_odm_root=/odm
ro.oppo.my_preload_root=/my_preload
ro.oppo.my_heytap_root=/my_heytap
ro.oppo.my_stock_root=/my_stock
ro.oppo.oppo_custom_root=/my_company
ro.oppo.oppo_engineer_root=/my_engineering
ro.oppo.oppo_product_root=/my_product
ro.oppo.oppo_version_root=/my_version
ro.oppo.my_manifest_root=/my_manifest  
  " >> $systemdir/product/build.prop
}
build_modify

# oppo rc 初始化阶段更改
sed -i 's/on boot/on early-init/g' $systemdir/../init.oppo.rc

# 清理oppo selinux多余的policy文件
rm -rf $systemdir/etc/selinux/*debug*
if [ -e $systemdir/product/etc/selinux/mapping ];then
  rm -rf $systemdir/product/etc/selinux/*debug*
fi
if [ -e $systemdir/system_ext/etc/selinux/mapping ];then
  rm -rf $systemdir/system_ext/etc/selinux/*debug*
fi

# 删除多余文件
if [ -e $systemdir/../my_product/vendor/firmware ];then
  rm -rf $systemdir/../my_product/vendor/firmware
fi

# system patch
cp -frp $LOCALDIR/system/* $systemdir
cat $LOCALDIR/fs >> $configdir/system_fs_config
cat $LOCALDIR/contexts >> $configdir/system_file_contexts

echo "正在精简推广"
$toolsdir/apps_clean/oppo.sh "$systemdir/.." 
rm -rf $systemdir/system_ext/apex/*"v28"* 
#rm -rf $systemdir/system_ext/apex/*"v29"*

rm -rf $tmpdir
