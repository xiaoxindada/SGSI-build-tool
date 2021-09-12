#!/bin/bash

LOCALDIR=`cd "$( dirname ${BASH_SOURCE[0]} )" && pwd`
cd $LOCALDIR
source $LOCALDIR/../../bin.sh
source $LOCALDIR/../../language_helper.sh

echo "apex extract"
APEXEXTRACT="$LOCALDIR/deapexer.py"
TARGETDIR="$1"
APEXDIR="$2"

rm -rf $TARGETDIR/apex_extract.log
touch $TARGETDIR/apex_extract.log

APEXES=$(ls "$APEXDIR" | grep "\.apex$")
for APEX in $APEXES; do
    APEXNAME=$(echo "$APEX" | sed 's/\.apex//')
    if [[ -d "$APEXDIR/$APEXNAME" || -d "$APEXDIR/$APEX" ]] ; then
        continue
    fi
    mkdir -p "$APEXDIR/$APEXNAME"
    7z e -y "$APEXDIR/$APEX" apex_pubkey -o"$APEXDIR/$APEXNAME" >> $TARGETDIR/apex_extract.log
    $APEXEXTRACT extract "$APEXDIR/$APEX" "$APEXDIR/$APEXNAME"
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
   7z e -y "$APEXDIR/$CAPEXNAME.apex" apex_pubkey -o"$APEXDIR/$CAPEXNAME" >> $TARGETDIR/apex_extract.log
   $APEXEXTRACT "$APEXDIR/$CAPEXNAME.apex" "$APEXDIR/$CAPEXNAME"
   rm -rf "$APEXDIR/$CAPEXNAME/lost+found"
   rm -rf "$APEXDIR/$CAPEX"
done
