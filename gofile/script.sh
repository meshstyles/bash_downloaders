#!/bin/bash

link=$1
useragent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/97.0.4692.99 Safari/537.36 OPR/83.0.4254.27"

#link gofile.io/d/
#cutoff

gofile_verifytoken() {
    # this api might be obsoleted
    cached_token=$(cat "$tokenfile" | jq -r '.token')
    token_verification_request_status=$(curl "https://api.gofile.io/getAccountDetails?token=$token" | jq '.status')
    if [[ "$token_verification_request_status" == 'ok' ]]; then
        token="$cached_token"
        token_set="true"
    fi
}

gofile_you_want_to_continue() {
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
    token=$(curl 'https://api.gofile.io/accounts' \
        -H 'authority: api.gofile.io' \
        -H 'accept: */*' \
        -H 'accept-language: en-US,en;q=0.9' \
        -H 'cache-control: no-cache' \
        -H 'content-type: text/plain;charset=UTF-8' \
        -H 'origin: https://gofile.io' \
        -H 'pragma: no-cache' \
        -H 'referer: https://gofile.io/' \
        -H "user-agent: $useragent" \
        --data-raw '{}' | jq -r '.data.token')
    echo "{\"token\":\"$token\"}" >"$tokenfile"
fi

contentId=$(echo "${link##*\/d\/}" | cut -d '?' -f 1 | cut -d '/' -f 1)
echo "[Hgofile-io] tokens : $token"
echo "[Hgofile-io] contentId : $contentId"

mkdir "gofolder($contentId)" || gofile_you_want_to_continue
cd "gofolder($contentId)"

# https://stackoverflow.com/questions/5080988/how-to-extract-string-following-a-pattern-with-grep-regex-or-perl
# appdata.wt = "
websiteToken=$(curl 'https://gofile.io/dist/js/global.js' \
    -H 'authority: gofile.io' \
    -H 'accept: */*' \
    -H 'accept-language: en-US,en;q=0.9' \
    -H 'referer: https://gofile.io/' \
    -H "user-agent: ${useragent}" \
    --compressed | grep -Po 'appdata.wt = "\K.*?(?=")')

echo "[Hgofile-io] websiteToken: $websiteToken"
url="https://api.gofile.io/contents/$contentId?wt=$websiteToken"
api_file_response=$(curl "$url" \
    -H 'accept: */*' \
    -H 'accept-language: en-US,en;q=0.9' \
    -H "authorization: Bearer $token" \
    -H 'cache-control: no-cache' \
    -H 'origin: https://gofile.io' \
    -H 'pragma: no-cache' \
    -H 'referer: https://gofile.io/' \
    -H "user-agent: $useragent")

echo "[Hgofile-io] API url $url"
for search_child in $(echo "$api_file_response" | jq -r '.data.children | keys[]'); do
    file_object=$(echo "$api_file_response" | jq '.data.children' | jq ".[\"$search_child\"]")
    echo "$file_object"
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
