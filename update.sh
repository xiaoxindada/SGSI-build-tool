#!/bin/bash

LOCALDIR=$(cd "$(dirname ${BASH_SOURCE[0]})" && pwd)
cd $LOCALDIR
source ./language_helper.sh

url="https://github.com/xiaoxindada/SGSI-build-tool"
branch="12"

if [ ! -d ".git" ]; then
  echo "$UPDATER_MSG1"
  select update in "Update" "Exit"; do
    case $update in
    "Update")
      echo "$UPDATER_MSG2"
      git init
      git checkout -B $url
      git remote add origin $url
      git fetch $url $branch
      git remote -v
      git reset --hard FETCH_HEAD
      git clean -df
      git pull origin $branch
      git branch --set-upstream-to=origin/$branch
      git submodule update --init --recursive
      git pull --recurse-submodules
      break
      ;;
    "Exit")
      break
      ;;
    esac
  done
  exit 0
fi

git submodule update --init --recursive
git pull --recurse-submodules
