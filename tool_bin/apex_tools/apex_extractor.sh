#!/bin/bash

LOCALDIR=`cd "$( dirname ${BASH_SOURCE[0]} )" && pwd`
cd $LOCALDIR
source $LOCALDIR/../../bin.sh

echo "apex extract"
APEXEXTRACT="$LOCALDIR/deapexer.py"
APEXDIR="$1"

APEXES=$(ls "$APEXDIR" | grep "\.apex$")
for APEX in $APEXES; do
    google_check=$(ls "$APEXDIR" | grep ".google")
    if [[ $google_check ]]; then
        APEXNAME=$(echo "$APEX" | sed 's/.google//g' | sed 's/.apex//g')
    else
        APEXNAME=$(echo "$APEX" | sed 's/.apex//g')
    fi
    mkdir -p "$APEXDIR/$APEXNAME"
    7z e -y "$APEXDIR/$APEX" apex_pubkey -o"$APEXDIR/$APEXNAME" >> $TARGETDIR/apex_extract.log
    $APEXEXTRACT extract "$APEXDIR/$APEX" "$APEXDIR/$APEXNAME"
    rm -rf "$APEXDIR/$APEXNAME/lost+found"
    #rm -rf "$APEXDIR/$APEX"
done
