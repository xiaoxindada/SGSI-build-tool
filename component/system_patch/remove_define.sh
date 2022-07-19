#!/bin/bash
LOCALDIR=`cd "$( dirname ${BASH_SOURCE[0]} )" && pwd`
cd $LOCALDIR

target_fs="$LOCALDIR/add_repack_fs"
target_contexts="$LOCALDIR/add_repack_contexts"

sed -i '/bin\/netd/d' $target_fs
sed -i '/bin\/netd/d' $target_contexts
