#!/bin/bash

# Xiaoxin sGSI Build Tools - Build Environment Setup Utils
# Copyright (C) 2020 Xiaoxindada <2245062854@qq.com> && Pomelo Jiuyu <2652609017@qq.com>

LOCALDIR=`cd "$( dirname ${BASH_SOURCE[0]} )" && pwd`
cd $LOCALDIR

# Whether uses mirror for pip
USE_MIRROR_FOR_PIP=true
# Python pip mirror link
PIP_MIRROR=https://pypi.tuna.tsinghua.edu.cn/simple/

dump_welcome(){
    echo -e "\033[34m $(cat banner/banner) \033[0m"
    echo
    source ./language_helper.sh
    echo -e "\033[33m [$INFO_STR] $WELCOME - $ENVSETUP_TOOLS \033[0m"
    echo
}

dependency_install(){
    echo -e "\033[33m [$INFO_STR] $DETECTING_SYSTEM ... \033[0m"
    if [[ "$OSTYPE" == "linux-gnu" ]]; then
        echo -e "\033[33m [$INFO_STR] $DETECTED_LINUX \033[0m"
        echo -e "\033[33m [$INFO_STR] $INSTPKG_WITH_APT ... \033[0m"
        sudo apt update && sudo apt upgrade -y
        sudo apt install git p7zip curl wget unace unrar zip unzip p7zip-full p7zip-rar sharutils uudeview mpack arj cabextract file-roller aptitude device-tree-compiler squashfs-tools liblzma-dev liblz4-tool gawk aria2 selinux-utils busybox -y
        sudo apt update --fix-missing
        
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo -e "\033[33m [$INFO_STR] $DETECTED_MAC \033[0m"
        echo -e "\033[33m [$INFO_STR] $INSTPKG_WITH_HB ... \033[0m"
        brew install protobuf xz brotli lz4 aria2
    fi
}

python_install(){
        echo -e "\033[33m [$INFO_STR] $PY2ANDPIP_INST ... \033[0m"
        sudo apt-get --purge remove -y python3-pip
        sudo apt install python aptitude -y
        sudo aptitude install python-dev -y
        sudo add-apt-repository universe
        sudo python get-pip.py
        sudo apt install python3 python3-pip -y
}

pip_module_install(){
    echo -e "\033[33m [$INFO_STR] $INSTALLING_PYTHONMOD... \033[0m"
    if [[ "$USE_MIRROR_FOR_PIP" == "true" ]] ; then
        sudo pip install backports.lzma pycryptodome pycrypto -i $PIP_MIRROR
        sudo pip3 install backports.lzma pycryptodome pycrypto -i $PIP_MIRROR
    elif [[ "$USE_MIRROR_FOR_PIP" == "false" ]] ; then
        sudo pip install backports.lzma pycryptodome pycrypto
        sudo pip3 install backports.lzma pycryptodome pycrypto
    fi
    
    echo -e "\033[33m [$INFO_STR] $INSTALLING_PYTHONMOD requirements\033[0m"
    if [[ "$USE_MIRROR_FOR_PIP" == "true" ]] ; then
        for requirements_list in $(find $LOCALDIR -type f | grep "requirements.txt");do
            sudo pip install -r $requirements_list -i $PIP_MIRROR
            sudo pip3 install -r $requirements_list -i $PIP_MIRROR
        done
    elif [[ "$USE_MIRROR_FOR_PIP" == "false" ]] ; then
        for requirements_list in $(find $LOCALDIR -type f | grep "requirements.txt");do
            sudo pip install -r $requirements_list
            sudo pip3 install -r $requirements_list
        done
    fi
    sudo pip install --upgrade "protobuf"
    sudo pip3 install --upgrade "protobuf"
}

debug_packages_version(){
    if [[ "$2" == "java" ]] ; then
        $2 -version &> $2.ver
    elif [[ "$2" == "busybox" ]] ; then
        $2 --help | head -n 1 &> $2.ver    
    else
        $2 --version &> $2.ver
    fi
    TARGET_SOFTWARE_VERSION=$(cat $2.ver | head -n 1)
    echo -e "\033[33m [$DEBUG_STR] $1 $VERSION_STR: $TARGET_SOFTWARE_VERSION \033[0m"
    rm -rf $2.ver
}

java_install(){
    if apt list | grep -q openjdk-11-jdk ;then
        JAVA_PACKAGE="openjdk-11-jdk"
    else
        JAVA_PACKAGE="openjdk-8-jdk"
    fi
    UNINSTALL_PACKAGE="openjdk-8-jdk"
    if [[ "$JAVA_PACKAGE" != "$UNINSTALL_PACKAGE" ]];then
        sudo apt -y purge $UNINSTALL_PACKAGE
    fi
    echo -e "\033[33m [$INFO_STR] $INSTALLING_JAVAPKG: $JAVA_PACKAGE... \033[0m"
    sudo apt install -y $JAVA_PACKAGE
}

dump_welcome
{
    trap 'echo -e "\033[31m [$ERROR_STR] $FAILED_INSTPKG ! \033[0m"; exit 1' ERR
    java_install
    dependency_install
    python_install
    pip_module_install
}

debug_packages_version Python python
debug_packages_version Pip pip
debug_packages_version Python3 python3
debug_packages_version Pip3 pip3
debug_packages_version Java java
debug_packages_version Busybox busybox

echo -e "\033[32m [$INFO_STR] $SUCCFINISH_OPER: $ENVSETUP_TOOLS \033[0m"
echo -e "\033[32m [$INFO_STR] $SELECT_LANG_STR, $EXITING_STR... \033[0m"
