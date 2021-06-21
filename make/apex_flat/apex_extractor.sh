#!/bin/bash

LOCALDIR=`cd "$( dirname $0 )" && pwd`
cd $LOCALDIR
echo "ext4extract"
EXT4EXTRACT="./ext4extract.py"

APEXDIR="$1"
APEXES=$(ls "$APEXDIR" | grep ".apex")
for APEX in $APEXES; do
    google_check=$(ls "$APEXDIR" | grep ".google")
    if [[ $google_check ]]; then
        APEXNAME=$(echo "$APEX" | sed 's/.google//g' | sed 's/.apex//g')
    else
        APEXNAME=$(echo "$APEX" | sed 's/.apex//g')
    fi
    if [[ -d "$APEXDIR/$APEXNAME" ]]; then
        continue
    fi
    mkdir -p "$APEXDIR/$APEXNAME"
    7z e "$APEXDIR/$APEX" apex_payload.img apex_pubkey -o"$APEXDIR/$APEXNAME" >> "$TMPDIR"/zip.log
    $EXT4EXTRACT "$APEXDIR/$APEXNAME/apex_payload.img" -D "$APEXDIR/$APEXNAME" >> "$TMPDIR"/zip.log
    rm -rf "$APEXDIR/$APEXNAME/apex_payload.img"
    rm -rf "$APEXDIR/$APEXNAME/lost+found"
done
