#!/bin/bash

link=$1

#link "archive.org/"
#cutoff

# split links if details or dl and error if link is unfamiliar
if [[ "$link" == *"archive.org/details/"* ]] ; then
    archive_id=$(echo "${link#*archive.org/details/}" | cut -d '/' -f 1)
elif [[ "$link" == *"archive.org/download/"* ]] ; then
    archive_id=$(echo "${link#*archive.org/download/}" | cut -d '/' -f 1)
else
    echo "the link \"${link}\" is currently not supported please open an issue on https://github.com/meshstyles/little_helpers/"
    echo "this script just uses a script from that repository find out more in the findings.md"
    exit 1
fi

archive_api=$(wget "https://archive.org/details/${archive_id}&output=json" -q -O - )

archive_itemsr=$(echo $archive_api | jq -r '.files | keys' | jq -c -r '.[]' | grep -v -- "/${archive_id}_files.xml" | grep -v -- "/${archive_id}_archive.torrent" | grep -v -- "/${archive_id}_meta.sqlite" | grep -v -- "/${archive_id}_meta.xml" | grep -v -- "/${archive_id}_reviews.xml")

#make dir for archive listing in order to not accidentally mess up a home directory
mkdir "$archive_id"
cd "$archive_id"

#preserver ifs
SAVEIFS=$IFS   # Save current IFS
IFS=$'\n'      # Change IFS to new line

archive_items=($archive_itemsr)

# return to default ifs (let's hope this does not break other stuff but otherwise you know what to do!)
IFS=$SAVEIFS

for archive_item_link_with_path in "${archive_items[@]}"
do
    # info: there is no need for / between archive_id and archive_item_link_with_path becuase it's already included in archive_item_link_with_path
    archive_item_download="https://archive.org/download/${archive_id}${archive_item_link_with_path}"

    fliepath=$(echo ${archive_item_download#*${archive_id}} | sed 's/%20/ /g')
    echo $fliepath

    #preserver ifs
    SAVEIFS=$IFS   # Save current IFS
    IFS=$'/'      # Change IFS to new line

    arr=($fliepath)

    # return to default ifs (let's hope this does not break other stuff but otherwise you know what to do!)
    IFS=$SAVEIFS

    # creating folders 
    # removing last item (filename) from dl path that split into arr and create folders 
    filename=$(echo ${arr[-1]})
    unset arr[-1]
    cur_pwd=$(pwd)
    for fodler in "${arr[@]}"
    do
        # avoid trying to create "" folders
        if [[ "$fodler" == "" ]] ; then
            echo > /dev/null
        else 
            mkdir "${fodler}"
            cd "${fodler}"
        fi
    done

    # then download item to drive
    wget -c -q --show-progress  "$archive_item_download"

    # go back to the starting point
    cd $cur_pwd

done
