#!/bin/bash

LOCALDIR=`cd "$( dirname $0 )" && pwd`
cd $LOCALDIR

if [ ! -d ".git" ];then
  echo "检测到当前为使用git同步工具，是否为你强制使用git同步并更新？"
  select update in "Update" "Exit" ;do
    case $update in
      "Update")
        echo "正在强制使用git更新中,请准备好梯子"
        git init
        git checkout -B 12
        git remote add origin https://github.com/xiaoxindada/SGSI-build-tool.git
        git fetch https://github.com/xiaoxindada/SGSI-build-tool.git 12
        git remote -v
        git reset --hard FETCH_HEAD
        git clean -df
        git pull origin 12
        git branch --set-upstream-to=origin/12
        git submodule update --init --recursive
        git pull --recurse-submodules
        break;;
      "Exit")
        break;;
    esac
  done
  exit
fi

git submodule update --init --recursive
git pull --recurse-submodules

