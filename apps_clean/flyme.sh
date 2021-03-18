#!/bin/bash

LOCALDIR=`cd "$( dirname $0 )" && pwd`
cd $LOCALDIR

systemdir=$1

apps_dir="
DataMigration
Email
Life
PerfUI
Reader
RemoteCooperation
VideoClips
DesktopBackup
FamilyGuard
GmsCore
Phonesky_CN
"
for delete_dir in $apps_dir ;do
  find $systemdir -type d -name "$delete_dir" | xargs rm -rf
done
