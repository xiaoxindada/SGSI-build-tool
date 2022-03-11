#!/bin/bash

FILE="$1"
LINE_CONTENT="$2"

flag=true
while IFS= read -r line;
do
    if [[ "$line" == *"$LINE_CONTENT"* ]]; then
        flag=false
        continue
    fi
    $flag && echo "$line"
    if ! $flag && [[ "$line" == "# from variable "* ]]; then
        flag=true
        echo "$line"
        continue
    fi
done  < "$FILE"

