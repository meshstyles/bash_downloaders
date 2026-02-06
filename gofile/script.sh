#!/bin/bash

link=$1
useragent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/97.0.4692.99 Safari/537.36 OPR/83.0.4254.27"

#link "gofile.io/d/"
#cutoff

contentId=$(echo "${link##*\/d\/}" | cut -d '?' -f 1 | cut -d '/' -f 1)
mkdir "gofolder($contentId)"
cd "gofolder($contentId)"

curl "https://gofile.io/d/$contentId" \
  -H 'accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7' \
  -H 'accept-language: en-US,en;q=0.9' \
  -H 'cache-control: no-cache' \
  -H 'pragma: no-cache' \
  -H 'priority: u=0, i' \
  -H 'referer: https://simpcity.cr/' \
  -H 'upgrade-insecure-requests: 1' \
  -H "user-agent: $useragent" > /dev/null

accountInfo=$(curl 'https://api.gofile.io/accounts' \
  -X 'POST' \
  -H 'accept: */*' \
  -H 'accept-language: en-US,en;q=0.9' \
  -H 'cache-control: no-cache' \
  -H 'content-length: 0' \
  -H 'origin: https://gofile.io' \
  -H 'pragma: no-cache' \
  -H 'priority: u=1, i' \
  -H 'referer: https://gofile.io/' \
  -H "user-agent: $useragent")

token=$(echo "$accountInfo" | jq '.data.token' -r);

echo "[Hgofile-io] tokens : $token"
echo "[Hgofile-io] contentId : $contentId"

# https://stackoverflow.com/questions/5080988/how-to-extract-string-following-a-pattern-with-grep-regex-or-perl
# appdata.wt = "
websiteToken=$(curl 'https://gofile.io/dist/js/config.js' \
    -b "accountToken=$token" \
    -H 'authority: gofile.io' \
    -H 'accept: */*' \
    -H 'accept-language: en-US,en;q=0.9' \
    -H 'referer: https://gofile.io/' \
    -H "user-agent: ${useragent}" \
    --compressed | grep -Po 'appdata.wt = "\K.*?(?=")')

echo "[Hgofile-io] websiteToken : $websiteToken"

fileApiUrl="https://api.gofile.io/contents/$contentId?contentFilter=&page=1&pageSize=1000&sortField=name&sortDirection=1"

fileInfo=$(curl "$fileApiUrl" \
  -H 'accept: */*' \
  -H 'accept-language: en-US,en;q=0.9' \
  -H "authorization: Bearer $token" \
  -H 'cache-control: no-cache' \
  -H 'origin: https://gofile.io' \
  -H 'pragma: no-cache' \
  -H 'priority: u=1, i' \
  -H 'referer: https://gofile.io/' \
  -H 'sec-ch-ua: "Not(A:Brand";v="8", "Chromium";v="144"' \
  -H 'sec-ch-ua-mobile: ?0' \
  -H 'sec-ch-ua-platform: "Linux"' \
  -H 'sec-fetch-dest: empty' \
  -H 'sec-fetch-mode: cors' \
  -H 'sec-fetch-site: same-site' \
  -H "user-agent: $useragent" \
  -H "x-website-token: $websiteToken")

for search_child in $(echo "$fileInfo" | jq -r '.data.children | keys[]'); do
    file_object=$(echo "$fileInfo" | jq '.data.children' | jq ".[\"$search_child\"]")
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
        "$file_directLink" -L -C - -o "$file_name"
done
