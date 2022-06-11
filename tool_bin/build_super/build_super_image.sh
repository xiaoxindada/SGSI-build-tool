#!/bin/bash

# Copyright (C) 2022 Xiaoxindada <2245062854@qq.com>

LOCALDIR=$(cd "$(dirname ${BASH_SOURCE[0]})" && pwd)
cd $LOCALDIR
lpmake="$LOCALDIR/lpmake"

abort() {
  echo -e $*
  exit 1
}

image_check() {
  if ! (ls | grep -qo "\.img$"); then
    abort "image not found"
  fi

  # image format check
  for image in $(ls | grep "\.img$"); do
    echo "error=false" >error
    if file $image | grep -qo "sparse"; then
      echo "$image 不为 raw image"
      echo "error=true" >error
    fi
  done
  if [ $(cat error | cut -d "=" -f 2) = true ]; then
    abort "image 格式检查失败"
  fi
  rm -rf error
}

create_super_image() {
  export images=()
  for image in $(ls | grep "\.img$"); do
    images+=" $image"
  done
  [ -z "${images[@]}" ] && abort "没有找到需要打包的img 请把img放在 $LOCALDIR"

  echo -e "\n"
  echo -e "请输入super分区的 group 如果不知道可以输入: main (安卓默认)"
  echo -e "ab vab设备不需要带_a _b; 例子: 原数据: main_a 输入 main 其他同理)"
  echo -e "获取数据方法: 手机输入 lpdump super 输出如下:"
  echo -e "
  ......
  ------------------------
    Name: system_a
    Group: mot_dp_group_a
    Attributes: readonly
    Extents:
      0 .. 2250999 linear super 6039552
      2251000 .. 7021847 linear super 1266736
      7021848 .. 7550295 linear super 9750464
      7550296 .. 7620839 linear super 12070080
  ------------------------
    Name: system_b
    Group: mot_dp_group_b
    Attributes: readonly
    Extents:
      0 .. 344927 linear super 8292352
  ------------------------

  输入 Group 后面的内容
  请输入super group:"
  read super_group

  echo "
  打包大小需要带单位 G, M (只支持整数其他一律使用字节为单位)
  用字节为单位打包时大小无需带单位

  请输入super分区大小:"
  read super_size

  sizeM="$(echo "$super_size" | sed 's/M//g')"
  sizeG="$(echo "$super_size" | sed 's/G//g')"

  if [ $(echo "$super_size" | grep 'M') ]; then
    super_final_size="$(($sizeM * 1024 * 1024))"
  elif [ $(echo "$super_size" | grep 'G') ]; then
    super_final_size="$(($sizeG * 1024 * 1024 * 1024))"
  else
    super_final_size="$super_size"
  fi

  # a_only ext args
  for image in ${images[@]}; do
    local partition_name=$(echo $image | sed 's/\.img//g')
    local size=$(stat -c %s $image)
    local ext_a_only_cmd="$ext_a_only_cmd --partition ${partition_name}:readonly:${size}:${super_group} --image $partition_name=$image"
  done

  # ab ext args
  for partition_name in $(echo ${images[@]} | sed -e 's/\.img//g' -e 's/_a\b//' -e 's/_b\b//'); do
    local size=$(stat -c %s ${partition_name}.img)
    local ext_ab_cmd="$ext_ab_cmd --partition ${partition_name}_a:readonly:${size}:${super_group}_a --image ${partition_name}_a=${partition_name}.img"
  done

  # virtual_ab args
  for partition_name in $(echo ${images[@]} | sed -e 's/\.img//g' -e 's/_a\b//' -e 's/_b\b//'); do
    local size=$(stat -c %s ${partition_name}.img)
    local ext_virtual_ab_cmd="$ext_virtual_ab_cmd --partition ${partition_name}_a:readonly:${size}:${super_group}_a --image ${partition_name}_a=${partition_name}.img --partition ${partition_name}_b:readonly:0:${super_group}_b"
  done

  local sparse_cmd=""
  while true; do
    read -p "是否生成 sparse (simg)格式的 super.img(y/n): " sparse
    case $sparse in
    "y" | "Y" | "yes" | "YES")
      local sparse_cmd="--sparse"
      break
      ;;
    "n" | "N" | "no" | "NO")
      local sparse_cmd=""
      break
      ;;
    *) echo "输入错误" ;;
    esac
  done

  echo "支持的super.img类型有: a_only ab virtual_ab (注意ab分区只支持打包成 slot_a 不会包含 slot_b)"
  local base_cmd="--metadata-size 65536 --super-name super"
  while true; do
    read -p "请输入需要生成的类型: " super_type
    case $super_type in
    "a_only")
      base_cmd+=" --device super:$super_final_size"
      base_cmd+=" --group $super_group:$super_final_size"
      final_cmd="$base_cmd --metadata-slots 2 $ext_a_only_cmd $sparse_cmd"
      break
      ;;
    "ab")
      base_cmd+=" --device super:$super_final_size"
      base_cmd+=" --group ${super_group}_a:$super_final_size"
      base_cmd+=" --group ${super_group}_b:$super_final_size"
      final_cmd="$base_cmd --metadata-slots 3 $ext_ab_cmd $sparse_cmd"
      break
      ;;
    "virtual_ab")
      base_cmd+=" --device super:$super_final_size"
      base_cmd+=" --group ${super_group}_a:$super_final_size"
      base_cmd+=" --group ${super_group}_b:$super_final_size"
      final_cmd="$base_cmd --metadata-slots 3 --virtual-ab $ext_virtual_ab_cmd $sparse_cmd"
      break
      ;;
    *)
      echo "输入错误！清重试"
      ;;
    esac
  done

  # create super.img
  local super_new_img="$LOCALDIR/super_new.img"
  local partition_list=($(echo ${images[@]} | sed 's/\.img//g'))

  rm -rf $super_new_img
  echo -e "当前打包的分区为: ${partition_list[@]}\n"
  echo "$lpmake $final_cmd --output $super_new_img"
  eval $lpmake $final_cmd --output $super_new_img
  if [ -s $super_new_img ]; then
    echo "$super_new_img 生成完毕"
    exit 0
  else
    echo "$super_new_img 生成失败"
    exit 1
  fi
}

image_check
create_super_image
