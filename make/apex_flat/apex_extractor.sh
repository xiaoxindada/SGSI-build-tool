#!/bin/bash

LOCALDIR=`cd "$( dirname $0 )" && pwd`
cd $LOCALDIR
echo "ext4extract"
EXT4EXTRACT="./ext4extract.py"

APEXDIR="$1"
APEXES=$(ls "$APEXDIR" | grep ".apex" | grep -v ".capex" )
for APEX in $APEXES; do
    APEXNAME=$(echo "$APEX" | sed 's/.apex//')
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

CAPEXES=$(ls "$APEXDIR" | grep ".capex" )
for CAPEX in $CAPEXES; do
   if [[ -z $CAPEX ]] ; then
       continue
   fi
   CAPEXNAME=$(echo "$CAPEX" | sed 's/.capex//')
   7z e -y "$APEXDIR/$CAPEX" original_apex -o"$APEXDIR" >> "$TMPDIR"/zip.log
   rm -rf "$APEXDIR/$CAPEX"
   mv -f "$APEXDIR/original_apex" "$APEXDIR/$CAPEXNAME.apex"
   mkdir -p "$APEXDIR/$CAPEXNAME"
   7z e -y "$APEXDIR/$CAPEXNAME.apex" apex_payload.img apex_pubkey -o"$APEXDIR/$CAPEXNAME" >> "$TMPDIR"/zip.log
   $EXT4EXTRACT "$APEXDIR/$CAPEXNAME/apex_payload.img" -D "$APEXDIR/$CAPEXNAME" >> "$TMPDIR"/zip.log
   rm -rf "$APEXDIR/$CAPEXNAME/apex_payload.img"
   rm -rf "$APEXDIR/$CAPEXNAME/lost+found"
   #rm -rf "$APEXDIR/$CAPEX"
done
