#!/bin/bash

# Xiaoxin sGSI Build Tools - Multi Language Helper
# Copyright (C) 2021 Xiaoxindada <2245062854@qq.com> && Jiuyu <2652609017@qq.com>

LANGDIR=`cd "$( dirname ${BASH_SOURCE[0]} )" && pwd`

usage(){
	echo "$0 <language>"
}

dump_support_lang(){
	echo "1.简体中文 (Simplified Chinese)"
    	echo "2.English"
}

CURRENT_LANG=$(echo $LANG | awk -F . '{print $1}')
TARGET_LANG="$1"

if [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
	usage
	echo "Support list:"
	dump_support_lang
	exit 1
fi

case $TARGET_LANG in
	"zh_CN"|"Chinese")
		source $LANGDIR/lang/zh_CN
		echo "Support list:"
		dump_support_lang
		echo
		echo $TARGET_LANG
		echo $LANG_AUTHOR
		echo "zh_CN" > $LANGDIR/.lang_flag
		;;
	"en_US"|"English")	
		source $LANGDIR/lang/en_US
		echo "Support list:"
		dump_support_lang
		echo
		echo $TARGET_LANG
		echo $LANG_AUTHOR
		echo "en_US" > $LANGDIR/.lang_flag
		;;
esac

if [ ! -f $LANGDIR/.lang_flag ]; then
	echo "Can't find $LANGDIR/.lang_flag use zh_CN language by default"
	echo "zh_CN" > $LANGDIR/.lang_flag
fi

source $LANGDIR/lang/$(cat $LANGDIR/.lang_flag)
