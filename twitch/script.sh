#!/bin/bash

link="${1}"
useragent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.45 Safari/537.36 OPR/82.0.4227.23"

#link "twitch.tv/"
#cutoff

echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo "@@@                                                                 @@@"
echo "@@@if the download speed is under 1.00x there will be missing frames@@@"
echo "@@@                                                                 @@@"
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo "@@@                                                                 @@@"
echo "@@@    close other programms or downloads if you get below 1.00x    @@@"
echo "@@@                                                                 @@@"
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo "@@@                                                                 @@@"
echo "@@@  attention ads may be included in the recording of the stream   @@@"
echo "@@@                                                                 @@@"
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"

# cut down the link to obtain username
username="${link##*twitch.tv\/}"
username="${username%%\?*}"
username="${username%%\/*}"

# download main page
page=$(curl "https://www.twitch.tv/$username" \
  -H 'Connection: keep-alive' \
  -H 'Cache-Control: max-age=0' \
  -H 'sec-ch-ua: " Not A;Brand";v="99", "Chromium";v="98", "Microsoft Edge";v="98"' \
  -H 'sec-ch-ua-mobile: ?0' \
  -H 'sec-ch-ua-platform: "Windows"' \
  -H 'Upgrade-Insecure-Requests: 1' \
  -H "User-Agent: ${useragent}" \
  -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9' \
  -H 'Sec-Fetch-Site: none' \
  -H 'Sec-Fetch-Mode: navigate' \
  -H 'Sec-Fetch-User: ?1' \
  -H 'Sec-Fetch-Dest: document' \
  -H 'Accept-Language: en-US,en;q=0.9,de;q=0.8' \
  --compressed)

player_token=$(echo "$page" | sed 's/5e3:"/\n/g' | sed -n 3p | cut -d '"' -f 1)
client_id=$(echo "$page" | sed 's/clientId=\"/\n/g' | sed -n 2p | cut -d '"' -f 1)

# download player and extract player version dynamically
player_version=$(curl "https://static.twitchcdn.net/assets/player-core-variant-a-${player_token}.js" --compressed | sed 's/getVersion=function(){return"/\n/' | sed -n 2p | cut -d '-' -f 1)

echo $player_version
echo $client_id

seconds=$(date +%s)
p_random_number=${seconds: -7}

# generate "valid" random string w/o space slashes and other char
random_char32_t (){
    random_string=$(head -n 5 /dev/urandom | base64 | sed "s/=/G/g; s/[ /+]/Y/g")
    random_string=${random_string: -32}
    echo $random_string | grep ' ' > /dev/null && random_char32_t
}

random_char32_t
play_session_random_id=random_string

random_char32_t
device_id=random_string

echo $play_session_random_id
echo $device_id

# obtain signature and stream token to request playback parent stream
stream_token_api=$(curl 'https://gql.twitch.tv/gql' \
  -H 'Connection: keep-alive' \
  -H 'sec-ch-ua: " Not A;Brand";v="99", "Chromium";v="98", "Microsoft Edge";v="98"' \
  -H 'Accept-Language: en-US' \
  -H 'sec-ch-ua-mobile: ?0' \
  -H 'Authorization: undefined' \
  -H 'Content-Type: text/plain; charset=UTF-8' \
  -H 'Accept: */*' \
  -H "Device-ID: ${device_id}" \
  -H "User-Agent: ${useragent}" \
  -H "Client-ID: ${client_id}" \
  -H 'sec-ch-ua-platform: "Windows"' \
  -H 'Origin: https://www.twitch.tv' \
  -H 'Sec-Fetch-Site: same-site' \
  -H 'Sec-Fetch-Mode: cors' \
  -H 'Sec-Fetch-Dest: empty' \
  -H 'Referer: https://www.twitch.tv/' \
  --data-raw $'{"operationName":"PlaybackAccessToken_Template","query":"query PlaybackAccessToken_Template($login: String\u0021, $isLive: Boolean\u0021, $vodID: ID\u0021, $isVod: Boolean\u0021, $playerType: String\u0021) {  streamPlaybackAccessToken(channelName: $login, params: {platform: \\"web\\", playerBackend: \\"mediaplayer\\", playerType: $playerType}) @include(if: $isLive) {    value    signature    __typename  }  videoPlaybackAccessToken(id: $vodID, params: {platform: \\"web\\", playerBackend: \\"mediaplayer\\", playerType: $playerType}) @include(if: $isVod) {    value    signature    __typename  }}","variables":{"isLive":true,"login":"'$username'","isVod":false,"vodID":"","playerType":"site"}}' \
  --compressed)

signature=$(echo "$stream_token_api" | jq -r '.data.streamPlaybackAccessToken.signature')
token=$(echo "$stream_token_api" | jq -r '.data.streamPlaybackAccessToken.value' | sed "s/\"/%22/g; s/\:/%3A/g; s/,/%2C/g; s/{/%7B/g; s/}/%7D/g; s/\[/%5B/g; s/\]/%5D/g")

echo $signature
echo $token
echo $stream_token_api

# userstream
mainuser_hls=$(curl "https://usher.ttvnw.net/api/channel/hls/$username.m3u8?allow_source=true&fast_bread=true&p=${p_random_number}&play_session_id=${play_session_random_id}&player_backend=mediaplayer&playlist_include_framerate=true&reassignments_supported=true&sig=${signature}&supported_codecs=avc1&token=${token}&cdm=wv&player_version=${player_version}" \
  -H 'Accept: application/x-mpegURL, application/vnd.apple.mpegurl, application/json, text/plain' \
  -H 'Referer: ' \
  -H "User-Agent: ${useragent}" \
  --compressed)

# stout stream w/o newline, parte it for bandwith and choose highest by using grep and with stream url in same line
echo "$mainuser_hls"
eval_mainuser_hls=$(echo $mainuser_hls  | sed 's/#/\n#/g')

list_of_res=$(echo "$eval_mainuser_hls" | grep "BANDWIDTH=" | sed 's/#EXT-X-STREAM-INF:BANDWIDTH=//g' | cut -d ',' -f 1)
array_of_res=($list_of_res)
max_res=0
for res in "${array_of_res[@]}"
do
    if [ "$res" -gt "$max_res" ]; then
        max_res="$res"
    fi
done
echo $list_of_res
echo "selected $max_res"
playlist_url=$(echo "$eval_mainuser_hls" | grep "$max_res")
playlist_url=${playlist_url##*https}
playlist_url="https$playlist_url"

# download stream
ffmpeg -i "${playlist_url}" -bsf:a aac_adtstoasc -vcodec copy -c copy -crf 50 "${username}$(date +%s).mp4"
