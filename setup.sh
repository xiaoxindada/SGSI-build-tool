#!/bin/bash

# Xiaoxin sGSI Build Tools - Build Environment Setup Utils
# Copyright (C) 2020 Xiaoxindada <2245062854@qq.com> && Pomelo Jiuyu <2652609017@qq.com>

LOCALDIR=`cd "$( dirname $0 )" && pwd`
cd $LOCALDIR

# Whether uses mirror for pip
USE_MIRROR_FOR_PIP=true
# Python pip mirror link
PIP_MIRROR=https://pypi.tuna.tsinghua.edu.cn/simple/

dump_welcome(){
    echo -e "\033[34m $(cat banner/banner) \033[0m"
    echo
    echo -e "\033[33m [INFO] Welcome to Xiaoxin sGSI Build Tools - Build Environment Setup Utils \033[0m"
    echo
}

dependency_install(){
    echo -e "\033[33m [INFO] Detecting System... \033[0m"
    if [[ "$OSTYPE" == "linux-gnu" ]]; then
        echo -e "\033[33m [DEBUG] Linux Detected \033[0m"
        echo -e "\033[33m [INFO] Installing Packages via apt... \033[0m"
        sudo apt update && sudo apt upgrade -y
        sudo apt install git p7zip openjdk-8-jdk curl cpio wget unace unrar zip unzip p7zip-full p7zip-rar sharutils uudeview mpack arj cabextract file-roller aptitude device-tree-compiler liblzma-dev liblz4-tool gawk aria2 selinux-utils busybox -y
        sudo apt update --fix-missing
        
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo -e "\033[33m [DEBUG] macOS Detected \033[0m"
        echo -e "\033[33m [INFO] Installing Packages via homebrew... \033[0m"
        brew install protobuf xz brotli lz4 aria2
    fi
}

python_install(){
        echo -e "\033[33m [INFO] Python and Pip install... \033[0m"
        sudo apt-get --purge remove -y python3-pip
        sudo apt install python aptitude -y
        sudo aptitude install python-dev -y
        sudo add-apt-repository universe
        sudo python get-pip.py
        sudo apt install python3 python3-pip -y
}

pip_module_install(){
    echo -e "\033[33m [INFO] Python2 and Python3 module install... \033[0m"
    if [[ "$USE_MIRROR_FOR_PIP" == "true" ]] ; then
        echo -e "\033[33m [INFO] Installing python packages from mirror... \033[0m"
        sudo pip install protobuf backports.lzma protobuf pycryptodome pycrypto -i $PIP_MIRROR
        sudo pip3 install protobuf backports.lzma protobuf pycryptodome pycrypto -i $PIP_MIRROR
    elif [[ "$USE_MIRROR_FOR_PIP" == "false" ]] ; then
        echo -e "\033[33m [INFO] Installing python packages from python-pip offical... \033[0m"
        sudo pip install protobuf backports.lzma protobuf pycryptodome pycrypto
        sudo pip3 install protobuf backports.lzma protobuf pycryptodome pycrypto 
    fi
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
    echo -e "\033[33m [DEBUG] $1 Version: $TARGET_SOFTWARE_VERSION \033[0m"
    rm -rf $2.ver
}

dump_welcome
dependency_install
python_install
pip_module_install
debug_packages_version Python python
debug_packages_version Pip pip
debug_packages_version Python3 python3
debug_packages_version Pip3 pip3
debug_packages_version Java java
debug_packages_version Busybox busybox

echo -e "\033[33m [INFO] Successfully Finished Build Environment Setup Utils, Exiting... \033[0m"
