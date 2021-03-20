#!/bin/bash

LOCALDIR=`cd "$( dirname $0 )" && pwd`
cd $LOCALDIR
echo "ext4extract"
EXT4EXTRACT="./ext4extract.py"

APEXDIR="$1"
APEXES=$(ls "$APEXDIR" | grep ".apex")
for APEX in $APEXES; do
    #if echo "$APEX" | grep -q "google" ;then
     #   APEXNAME=$(echo "$APEX" | sed 's/\.google//' | sed 's/.apex//')
    #else
        APEXNAME=$(echo "$APEX" | sed 's/.apex//')
    #fi
    if [[ -d "$APEXDIR/$APEXNAME" || -d "$APEXDIR/$APEX" ]] ; then
        continue
    fi    
    mkdir -p "$APEXDIR/$APEXNAME"
    7z e -y "$APEXDIR/$APEX" apex_payload.img apex_pubkey -o"$APEXDIR/$APEXNAME" >> "$TMPDIR"/zip.log
    $EXT4EXTRACT "$APEXDIR/$APEXNAME/apex_payload.img" -D "$APEXDIR/$APEXNAME" >> "$TMPDIR"/zip.log
    rm -rf "$APEXDIR/$APEXNAME/apex_payload.img"
    rm -rf "$APEXDIR/$APEXNAME/lost+found"
    #rm -rf "$APEXDIR/$APEX"
done
