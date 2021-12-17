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

# mitigate link from user shares
if [[ "$link" == *"vm.tiktok.com"* ]]; then
    # we ge a new "normalized" link
    get_page
    link=$(echo "$page" | pup 'a attr{href}' | sed 's/&amp;/&/g')
fi

# 
if [[ "$link" = *"m.tiktok.com/v/"* ]]; then
    get_page
    link=$(echo "$page" | pup 'a attr{href}'| sed 's/&amp;/&/g')
fi

get_page

# obtain parameters for download
video_id=$(echo ${link##*video\/} | cut -d '?' -f 1)
user_name=$(echo ${link##*\@} | cut -d '/' -f 1)
tiktok_video_url=$(echo "$page" | pup 'meta[property="og:video:secure_url"] attr{content}' | sed 's/\&amp;/\&/g')

echo "$tiktok_video_url"

#download video
wget "${tiktok_video_url}" \
    --user-agent="${useragent}" \
    --referer="https://www.tiktok.com/" \
    -O "${user_name}-${video_id}.mp4" || exit 1
