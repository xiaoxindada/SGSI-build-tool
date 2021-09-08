#!/bin/bash

# Most part of this program which is used to download files from Mega.NZ and MediaFire is under Copyright to stck-lzm at https://github.com/stck-lzm/badown

# Common Functions
function file_down() {
    aria2c -x16 -j$(nproc) -c -m10 --check-certificate=false --check-certificate=false -d "$2" -o "$3" "$1" > /dev/null 2>&1
}

# Mediafire
function mediafire() {
    file_url=$(wget -q -O- $1 | grep :\/\/download | awk -F'"' '{print $2}')
    file_down $file_url "$2" "$3"
}

# Google Drive
function gdrive() {
    FILE_ID="$(echo "${1:?}" | sed -r 's/.*([0-9a-zA-Z_-]{33}).*/\1/')"
    CONFIRM=$(wget --quiet --save-cookies /tmp/cookies.txt --keep-session-cookies --no-check-certificate "https://docs.google.com/uc?export=download&id=$FILE_ID" -O- | sed -rn 's/.*confirm=([0-9A-Za-z_]+).*/\1\n/p')
    aria2c -c -s16 -x16 -m10 --check-certificate=false --load-cookies /tmp/cookies.txt -d "$2" -o "$3" "https://docs.google.com/uc?export=download&confirm=$CONFIRM&id=$FILE_ID" > /dev/null 2>&1
}

# MEGA.nz Functions
function url_str() {
    echo $1 | awk '{gsub("-","+"); gsub("_","/"); gsub(",",""); print}'
}

function json_req() {
    wget -q -O- --post-data="$1" --header='Content-Type:application/json' "https://g.api.mega.co.nz/cs$2"
}

function key_solver() {
    echo -n $1 | base64 --decode --ignore-garbage 2>/dev/null | xxd -p | tr -d '\n'
}

function json_post() {
    echo $2 | awk -v c=$1 -F'"' '{for(i = 1; i <= NF; i++)
        {if($i==c)
            if((c=="t")||(c=="s")||(c=="ts"))
            {gsub(/[[:punct:]]/,"",$(i+1));print $(i+1);}
        else
            {print $(i+2);}
        }
    }'
}

function key_dec() {
    local var=$(key_solver "$(url_str $key)")
    echo $(url_str $1) | openssl enc -a -d -A -aes-128-ecb -K $var -iv "00000000000000000000000000000000" -nopad 2>/dev/null | base64
}

function size() {
    local i=0
    local var=$1
    local pad=$(((4 - ${#var} % 4) % 4))
    for i in $(seq 1 $pad); do var="$var="; done
    echo $var
}

function meta_dec_key() {
    local var
    var[0]=$((0x${1:00:16} ^ 0x${1:32:16}))
    var[1]=$((0x${1:16:16} ^ 0x${1:48:16}))
    meta_key=$(printf "%016x" ${var[*]})
    meta_iv="${1:32:16}0000000000000000"
}

function meta_dec() {
    echo -n $2 | openssl enc -a -A -d -aes-128-cbc -K $1 -iv "00000000000000000000000000000000" -nopad | tr -d '\0' 2>/dev/null
}

function mega_link_vars() {
    if [[ "$1" == *"/#"* ]]; then
        id=$(echo $1 | awk -F'!' '{print $2}')
        key=$(echo $1 | awk -F'!' '{print $3}')
        fld=$(echo $1 | awk -F'!' '{print $1}')
    else
        fld=$(echo $1 | awk '{gsub(/[^\/]*$/,"");print}')
        id=$(echo $1 | awk -F'/' '{print $NF}' | awk -F# '{print $1}')
        key=$(echo $1 | awk -F'/' '{print $NF}' | awk -F# '{print $2}')
    fi
}

function tree_gen() {
    local i=0
    while [[ $i -lt $2 ]] && ! [[ ${names[i]} == "$1" ]]; do
        let i++
    done
    if ! [[ $i == $2 ]]; then
        tree_gen ${parents[i]} $2
        meta_dec_key "$(key_solver $(key_dec $(size ${keys[i]})))"
        file_name="$(json_post 'n' "$(meta_dec $meta_key $(size $(url_str ${attrs[i]})))")"
        path=$path/$file_name
    fi
}

function file_downdec() {
    aria2c -c -s16 -x8 -m10 --summary-interval=0 --check-certificate=false -d "$5" -o "$6".tmp "$1"  > /dev/null 2>&1
    cat "$5/$6.tmp" | openssl enc -d -aes-128-ctr -K $3 -iv $4 > "$5/$6"
    rm -f "$5/$6.tmp"
}

# MEGA.nz
function mega() {
    mega_link_vars $1
    if [ "${fld: -1}" == "F" ] || [[ "$fld" == *"folder"* ]]; then
        json_req '[{"a":"f","c":1,"ca":1,"r":1}]' "?id=&n=$id" >.badown.tmp
        [[ $(file .badown.tmp) == *"gzip"* ]] && response1=$(cat .badown.tmp | gunzip) || response1=$(cat .badown.tmp)
        keys=($(json_post 'k' $response1 | awk -F':' '{print $2}'))
        names=($(json_post 'h' $response1))
        types=($(json_post 't' $response1))
        attrs=($(json_post 'a' $response1))
        sizes=($(json_post 's' $response1))
        parents=($(json_post 'p' $response1))
        for i in $(seq 0 $((${#types[@]} - 1))); do
            unset path
            tree_gen ${parents[i]} $((${#types[@]} - 1))
            meta_dec_key "$(key_solver $(key_dec $(size ${keys[i]})))"
            file_name="$(json_post 'n' "$(meta_dec $meta_key $(size $(url_str ${attrs[i]})))")"
            path=$path/$file_name
            if [ ${types[i]} == 1 ]; then
                sleep .5
                mkdir -p "$PWD$path"
            elif [ ${types[i]} == 0 ]; then
                file_url=$(json_post 'g' $(json_req "[{\"a\":\"g\",\"g\":1,\"n\":\"${names[i]}\"}]" "?id=&n=$id"))
                file_downdec $file_url "$file_name" $meta_key $meta_iv "$2" "$3"
                sleep .5
            fi
        done
    elif [ "${fld: -1}" == "#" ] || [[ "$fld" == *"file"* ]]; then
        meta_dec_key $(key_solver $(url_str $key))
        name_key=$(url_str $(json_post 'at' $(json_req "[{\"a\":\"g\", \"p\":\"$id\"}]" '?id=&ak=')))
        file_name="$(json_post 'n' "$(meta_dec $meta_key $(size $name_key))")"
        file_url=$(json_post 'g' $(json_req "[{\"a\":\"g\",\"g\":1,\"p\":\"$id\"}]" '?'))
        file_downdec $file_url "$file_name" $meta_key $meta_iv "$2" "$3"
    fi
}

if [[ "$1" == *"drive.google.com"* ]]; then
    gdrive "$1" "$2" "$3"
elif [[ "$1" == *"mediafire"* ]]; then
    mediafire "$1" "$2" "$3"
elif [[ "$1" == *"mega"* ]]; then
    mega "$1" "$2" "$3"
fi