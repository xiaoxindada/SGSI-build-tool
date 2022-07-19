#!/bin/bash

LOCALDIR=`cd "$( dirname ${BASH_SOURCE[0]} )" && pwd`
cd $LOCALDIR
source $LOCALDIR/../../bin.sh
source $LOCALDIR/../../language_helper.sh

echo "ext4extract"
EXT4EXTRACT="$LOCALDIR/ext4extract.py"
TARGETDIR="$LOCALDIR/../../workspace/out"
APEXDIR="$1"

rm -rf $TARGETDIR/apex_extract.log
touch $TARGETDIR/apex_extract.log

APEXES=$(ls "$APEXDIR" | grep "\.apex$")
for APEX in $APEXES; do
    APEXNAME=$(echo "$APEX" | sed 's/\.apex//')
    if [[ -d "$APEXDIR/$APEXNAME" || -d "$APEXDIR/$APEX" ]] ; then
        continue
    fi
    mkdir -p "$APEXDIR/$APEXNAME"
    7z e -y "$APEXDIR/$APEX" apex_payload.img apex_pubkey -o"$APEXDIR/$APEXNAME" >> $TARGETDIR/apex_extract.log
    $EXT4EXTRACT "$APEXDIR/$APEXNAME/apex_payload.img" -D "$APEXDIR/$APEXNAME"
    rm -rf "$APEXDIR/$APEXNAME/apex_payload.img"
    rm -rf "$APEXDIR/$APEXNAME/lost+found"
    #rm -rf "$APEXDIR/$APEX"
done

CAPEXES=$(ls "$APEXDIR" | grep "\.capex$" )
for CAPEX in $CAPEXES; do
   if [[ -z $CAPEX ]] ; then
       continue
   fi
   CAPEXNAME=$(echo "$CAPEX" | sed 's/\.capex//')
   7z e -y "$APEXDIR/$CAPEX" original_apex -o"$APEXDIR" >> $TARGETDIR/apex_extract.log
   mv -f "$APEXDIR/original_apex" "$APEXDIR/$CAPEXNAME.apex"
   mkdir -p "$APEXDIR/$CAPEXNAME"
   7z e -y "$APEXDIR/$CAPEXNAME.apex" apex_payload.img apex_pubkey -o"$APEXDIR/$CAPEXNAME" >> $TARGETDIR/apex_extract.log
   $EXT4EXTRACT "$APEXDIR/$CAPEXNAME/apex_payload.img" -D "$APEXDIR/$CAPEXNAME"
   rm -rf "$APEXDIR/$CAPEXNAME/apex_payload.img"
   rm -rf "$APEXDIR/$CAPEXNAME/lost+found"
   rm -rf "$APEXDIR/$CAPEX"
done
