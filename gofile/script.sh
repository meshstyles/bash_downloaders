#!/bin/bash

link=$1
useragent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/97.0.4692.99 Safari/537.36 OPR/83.0.4254.27"

#link "gofile.io/d/"
#cutoff

gofile_verifytoken(){
    
    cached_token=$(cat "$tokenfile" | jq -r '.token')
    token_verification_request_status=$(curl "https://api.gofile.io/getAccountDetails?token=$token" | jq '.status')
    if [[ "$token_verification_request_status" == 'ok' ]]; then
        token="$cached_token"
        token_set="true"
    fi
}

gofile_you_want_to_continue(){
    echo "[Hgofile-io] do you want to continue: \"yes\" "
    read continue_gofile

    if [[ "$continue_gofile" != "yes" ]]; then
        exit 0
    fi
}

# if mkdir fails stop
[ -d ~/.local/cache/ ] || mkdir ~/.local/cache/ || exit 1 

tokenfile="/home/$(whoami)/.local/cache/gofileio.token"
[ -f "$tokenfile" ] && gofile_verifytoken
[ -f "$tokenfile" ] || touch "$tokenfile"

if [[ "$token_set" != "true" ]]; then
    token=$(curl -H "User-Agent: ${useragent}" "https://api.gofile.io/createAccount" | jq -r '.data.token')
    echo "{\"token\":\"$token\"}" > "$tokenfile"
fi 

contentId=$(echo "${link##*\/d\/}" | cut -d '?' -f 1 | cut -d '/' -f 1)
echo "[Hgofile-io] tokens : $token"
echo "[Hgofile-io] contentId : $contentId"

mkdir "gofolder($contentId)" || gofile_you_want_to_continue
cd "gofolder($contentId)"

# https://stackoverflow.com/questions/5080988/how-to-extract-string-following-a-pattern-with-grep-regex-or-perl
websiteToken=$(curl 'https://gofile.io/dist/js/alljs.js' \
  -H 'authority: gofile.io' \
  -H 'accept: */*' \
  -H 'accept-language: en-US,en;q=0.9' \
  -H 'sec-ch-ua: "Not?A_Brand";v="8", "Chromium";v="108", "Microsoft Edge";v="108"' \
  -H 'sec-ch-ua-mobile: ?0' \
  -H 'sec-ch-ua-platform: "Windows"' \
  -H 'sec-fetch-dest: script' \
  -H 'sec-fetch-mode: no-cors' \
  -H 'sec-fetch-site: same-origin' \
  -H "user-agent: ${useragent}" \
  --compressed | grep -Po 'fetchData.websiteToken = "\K.*?(?=")')

url="https://api.gofile.io/getContent?contentId=${contentId}&token=${token}&websiteToken=${websiteToken}"
api_file_response=$(curl -H "User-Agent: ${useragent}" "$url")

for i in  $(echo "$api_file_response" | jq -r '.data.childs | keys | .[]'); do
    child=$(echo "$api_file_response" | jq -r ".data.childs[$i]")
    search_child=".\"$child\""
    file_object=$(echo "$api_file_response" | jq '.data.contents' | jq "$search_child")

    file_name=$(echo "$file_object" | jq -r '.name')
    file_directLink=$(echo "$file_object" | jq -r '.link')

    echo "========================="
    echo "[Hgofile-io] $file_name"
    echo "[Hgofile-io] $file_directLink"
    echo "========================="

    curl -H "User-Agent: ${useragent}" \
    -H 'referer: https://gofile.io/' \
    --cookie "accountToken=${token}" \
    "$file_directLink" -L -o "$file_name"

done
exit 0
