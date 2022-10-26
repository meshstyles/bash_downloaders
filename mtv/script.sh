#!/bin/bash

link=$1
useragent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/97.0.4692.99 Safari/537.36 OPR/83.0.4254.27"

#link "mtv.de/folgen/"
#cutoff

if [[ "$link" != 'https://'* ]]; then
    link=:"https://$link"
fi

authority=$(echo "$link" | cut -d '?' -f 1 | cut -d '/' -f 1)

page=$(curl "$link" \
  -H "authority: $authority" \
  -H 'accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9' \
  -H 'accept-language: de-DE,de;q=0.9' \
  -H 'cache-control: max-age=0' \
  -H 'sec-ch-ua: "Chromium";v="106", "Google Chrome";v="106", "Not;A=Brand";v="99"' \
  -H 'sec-ch-ua-mobile: ?0' \
  -H 'sec-ch-ua-platform: "Windows"' \
  -H 'sec-fetch-dest: document' \
  -H 'sec-fetch-mode: navigate' \
  -H 'sec-fetch-site: none' \
  -H 'sec-fetch-user: ?1' \
  -H 'upgrade-insecure-requests: 1' \
  -H "user-agent: $useragent" \
  --compressed)

# the line starts out like this
# window.__DATA__ = {"type":"Page","props":{"className":"video-player-template",
# so first select the line from the index.html cut from the first { and cut of the ; at the end
data=$(echo "$page" | grep "window.__DATA__")
data=$(echo "{${data#*\{}" | sed 's/;$//' )

contentIntermediaryCode=$(echo "$data" | jq '.props.edenData.contentRef' -r)
echo "[mtv-de] intermediary code: $contentIntermediaryCode"

if [[ "$contentIntermediaryCode" == "null" ]] || [[ "$contentIntermediaryCode" == '' ]]; then
    echo "[mtv-de] cant retieve info 1st step info"
    exit 1
fi

contentIntermediaryAPI=$(curl "https://media.mtvnservices.com/pmt/e1/access/index.html?uri=$contentIntermediaryCode&configtype=edge&ref=$link" \
  -H 'Accept: application/json' \
  -H 'accept-language: de-DE,de;q=0.9' \
  -H 'Connection: keep-alive' \
  -H "Origin: $authority" \
  -H "Referer: $authority" \
  -H 'Sec-Fetch-Dest: empty' \
  -H 'Sec-Fetch-Mode: cors' \
  -H 'Sec-Fetch-Site: cross-site' \
  -H "User-Agent: $useragent" \
  -H 'sec-ch-ua: "Chromium";v="106", "Google Chrome";v="106", "Not;A=Brand";v="99"' \
  -H 'sec-ch-ua-mobile: ?0' \
  -H 'sec-ch-ua-platform: "Windows"' \
  --compressed)

videoid=$(echo "$contentIntermediaryAPI" | jq '.feed.items[0].guid' -r)
echo "$videoid"
echo "[mtv-de] video code: $videoid"

if [[ "$videoid" == "null" ]] || [[ "$videoid" == '' ]]; then
    echo "[mtv-de] cant retieve info 2nd step info"
    exit 1
fi

contentAPI=$(curl "https://media-utils.mtvnservices.com/services/MediaGenerator/$videoid?arcStage=live&format=json&acceptMethods=hls&https=true&isEpisode=true&ratingIds=b22fa3cb-b8a4-4f1c-9ccd-fdf435246ac1,f32ecc8f-7018-457a-893e-876ba039bb1c,4fca9d87-2212-4b48-8b4b-52a2adb6ca86&ratingAcc=default&accountOverride=intl.mtvi.com&ep=82ac4273&tveprovider=null" \
  -H 'Accept: application/json' \
  -H 'accept-language: de-DE,de;q=0.9' \
  -H 'Connection: keep-alive' \
  -H "Origin: $authority" \
  -H "Referer: $authority" \
  -H 'Sec-Fetch-Dest: empty' \
  -H 'Sec-Fetch-Mode: cors' \
  -H 'Sec-Fetch-Site: cross-site' \
  -H "User-Agent: $useragent" \
  -H 'sec-ch-ua: "Chromium";v="106", "Google Chrome";v="106", "Not;A=Brand";v="99"' \
  -H 'sec-ch-ua-mobile: ?0' \
  -H 'sec-ch-ua-platform: "Windows"' \
  --compressed )

# so far there always only has been one video available so pick item[0]
mainHlsStream=$(echo "$contentAPI" | jq '.package.video.item[0].rendition[0].src' -r)
echo "[mtv-de] main HLS Stream: $mainHlsStream"

if [[ "$mainHlsStream" == "null" ]] || [[ "$mainHlsStream" == '' ]]; then
    echo "[mtv-de] cant retieve stream link step info"
    exit 1
fi

epname=$(echo "${link##*/folgen/}" | cut -d '/' -f 2  | sed "s/[:/|?]/-/g; s/%20/ /g; s/–/-/g; s/ $//; s/&amp;/\&/g" | cut -c-175 )
echo "[mtv-de] downloading $epname"

HLSauthority=$(echo "$link" | cut -d '?' -f 1 | cut -d '/' -f 1)

master_stream=$(curl "$mainHlsStream" \
  -H "authority: $HLSauthority" \
  -H 'accept: */*' \
  -H 'accept-language: de-DE,de;q=0.9' \
  -H "origin: $authority" \
  -H "referer: $authority" \
  -H 'sec-ch-ua: "Chromium";v="106", "Google Chrome";v="106", "Not;A=Brand";v="99"' \
  -H 'sec-ch-ua-mobile: ?0' \
  -H 'sec-ch-ua-platform: "Windows"' \
  -H 'sec-fetch-dest: empty' \
  -H 'sec-fetch-mode: cors' \
  -H 'sec-fetch-site: cross-site' \
  -H "user-agent: $useragent" \
  --compressed )

substreamlinkr=$(echo "$master_stream" | grep 'https://')
((resolution=0))

SAVEIFS=$IFS   # Save current IFS
IFS=$'\n'      # Change IFS to new line
substreamlinka=($substreamlinkr)
IFS=$SAVEIFS 
echo "starting download"
for substreamlink in "${substreamlinka[@]}"
do
    res=$(echo "${substreamlink#*stream_}" | cut -d '_' -f 1)
    height="${res#*x}"
    width="${res%x*}"
    echo "h: $height | w: $width "
    ((lresolution=$height*$width))
    # if normal stream in higher quality; overwrite url
    if (($lresolution > $resolution)); then
        resolution="$lresolution"
        gwidth="$width"
        gheight="$height"
    fi
done

streamlink=$(echo "$substreamlinkr" | grep "${gwidth}x${gheight}")
echo "[mtv-de] found stream in: $gwidth X $gheight"

ffmpeg -i "${streamlink}" -loglevel quiet -stats -c copy "${epname}-mtv.mp4"

echo "[mtv-de] done $epname"
