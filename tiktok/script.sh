#!/bin/bash

link="${1}"
useragent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.45 Safari/537.36 OPR/82.0.4227.23"

#link "tiktok.com"
#cutoff

get_page(){
    # download web page
    page=$(curl "$link" \
    -H 'authority: www.tiktok.com' \
    -H 'cache-control: max-age=0' \
    -H 'sec-ch-ua-mobile: ?0' \
    -H 'sec-ch-ua-platform: "Windows"' \
    -H 'upgrade-insecure-requests: 1' \
    -H "user-agent: ${useragent}" \
    -H 'accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9' \
    -H 'sec-fetch-site: none' \
    -H 'sec-fetch-mode: navigate' \
    -H 'sec-fetch-user: ?1' \
    -H 'sec-fetch-dest: document' \
    -H 'accept-language: en-US;q=0.8,en;q=0.7' \
    --compressed
    )
}

get_video_content(){
# download video
# exit if with code 1 whne the download fails
wget "${tiktok_video_url}" \
    --user-agent="${useragent}" \
    --referer="https://www.tiktok.com/" \
    -O "${user_name}-${video_id}.mp4" || exit 1
}

# resolve links from user share
if [[ "$link" == *"vm.tiktok.com"* ]]; then
    # we ge a new "normalized" link
    get_page
    link=$(echo "$page" | pup 'a attr{href}' | sed 's/&amp;/&/g')
fi

# resolve mobile site links to desktop
if [[ "$link" == *"m.tiktok.com/v/"* ]]; then
    get_page
    link=$(echo "$page" | pup 'a attr{href}'| sed 's/&amp;/&/g')
fi


# resolve link to desktop site and download
if [[ "$link" == *"/video/"* ]]; then
    get_page

    # obtain parameters for download
    video_id=$(echo ${link##*video\/} | cut -d '?' -f 1)
    user_name=$(echo ${link##*\@} | cut -d '/' -f 1)
    # this works since the relaxed json devides member variables by ','
    # than we can just filter for video urls and we'll select downloadAddr and fix it up
    tiktok_video_url=$(echo "$page" | pup 'script#sigi-persisted-data text{}' |  sed 's/,/,\n/g'  | grep "webapp.tiktok.com" | grep 'downloadAddr' | cut -d '"' -f 4 | sed 's/\\u002F/\//g')

    if [[ "$tiktok_video_url" == "" ]]; then
        echo "could not obtain video url"
        exit 2
    fi

    get_video_content

    # we need to exit here to have the next clause to be user profile downloads only
    exit 0

fi

# after here it should not be videos any more
# this is using user profile sites
if [[ "$link" == *"/@"* ]]; then

    echo "this is a user profile download"

    get_page
    # echo "$page" > index.html
    
    user_name=$(echo ${link##*\@} | cut -d '/' -f 1 | cut -d '?' -f 1)
    username_nonconforming=$(echo "$page" | pup 'script#Person text{}' | jq -r '.name' | sed "s/[:/|]/-/g; s/ $//; s/&amp;/\&/g")
    
    echo "$username_nonconforming"
    mkdir "$username_nonconforming"
    cd "$username_nonconforming"

    usercontent_list=$(echo "$page" | pup 'script#sigi-persisted-data text{}' | sed "s/window\['SIGI_STATE'\]=//g" | jq '.ItemList."user-post"')

    # echo "$usercontent_list" > videolist.json

    for k in  $(jq -r '.preloadList | keys | .[]' <<< "$usercontent_list"); do
        tiktok_video_url=$( echo $usercontent_list | jq ".preloadList[$k].url" -r)
        video_id=$( echo $usercontent_list | jq ".preloadList[$k].id" -r)
        
        get_video_content
    done

    cd ..

fi
