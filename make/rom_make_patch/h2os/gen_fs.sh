LOCALDIR=`cd "$( dirname $0 )" && pwd`
cd $LOCALDIR

bin="$LOCALDIR/../../../tool_bin"
configdir="$LOCALDIR/../../../out/config"
contexts="$LOCALDIR/contexts"
fs="$LOCALDIR/fs"

files=$(find ./system/ -name "*")

rm -rf $contexts $fs
for file in $files ;do
  if [ -d "$file" ];then
    echo "$file" | sed 's#\./#/#g' | sed 's/$/& 0 0 0755/g' | sed 's/^/&system/g' >>$fs
    if [ $(echo "$file" | grep "lib") ];then
      echo "$file" | sed 's#\./#/#g' | sed 's/$/& u:object_r:system_lib_file:s0/g' | sed 's/^/&\/system/g' >>$contexts
    elif [ $(echo "$file" | grep "lib64") ];then
      echo "$file" | sed 's#\./#/#g' | sed 's/$/& u:object_r:system_lib_file:s0/g' | sed 's/^/&\/system/g' >>$contexts
    else
      echo "$file" | sed 's#\./#/#g' | sed 's/$/& u:object_r:system_file:s0/g' | sed 's/^/&\/system/g' >>$contexts
    fi 
  fi

  if [ -f "$file" ];then
    echo "$file" | sed 's#\./#/#g' | sed 's/$/& 0 0 0644/g' | sed 's/^/&system/g' >>$fs
    if [ $(echo "$file" | grep ".so$") ];then
      echo "$file" | sed 's#\./#/#g' | sed 's/$/& u:object_r:system_lib_file:s0/g' | sed 's/^/&\/system/g' >>$contexts
    else
      echo "$file" | sed 's#\./#/#g' | sed 's/$/& u:object_r:system_file:s0/g' | sed 's/^/&\/system/g' >>$contexts
    fi
  fi
done

sed -i '1d' $contexts
sed -i '1d' $fs