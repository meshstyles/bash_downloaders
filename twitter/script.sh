#!/bin/bash

link="$1"
useragent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/95.0.4638.54 Safari/537.36 Edg/95.0.1020.40"

#link "twitter.com/"
#cutoff

tweetid=$(echo ${link##*status/} | cut -d '/' -f 1 | cut -d '?' -f 1)

echo "[twitter] downloading info for tweet $tweetid"

tweetInfo=$(curl "https://cdn.syndication.twimg.com/tweet-result?features=tfw_tweet_edit_backend%3Aoff%3Btfw_refsrc_session%3Aoff%3Btfw_tweet_result_migration_13979%3Atweet_result%3Btfw_sensitive_media_interstitial_13963%3Ainterstitial%3Btfw_experiments_cookie_expiration%3A1209600%3Btfw_duplicate_scribes_to_settings%3Aoff%3Btfw_user_follow_intent_14406%3Afollow%3Btfw_tweet_edit_frontend%3Aoff&id=${tweetid}&lang=en" \
  -H "user-agent: $useragent" -s )

# echo "$tweetInfo" > json.json

if [[ "$tweetInfo" != "" ]]; then
    tweetuser=$(echo "$tweetInfo" | jq -r '.user.screen_name')
    mkdir "$tweetuser"
    cd "$tweetuser"

    imgExist=$(echo "$tweetInfo" | jq -r ".photos[0].url")
    videosExist=$(echo "$tweetInfo" | jq -r '.video')
    # PHOTOS
    if [[ "$imgExist" != null ]]; then
        echo "[twitter] image(s) found"
        for j in  $(echo "$tweetInfo" | jq -r '.photos | keys | .[]'); do
            contentUrl=$(echo "$tweetInfo" | jq -r ".photos[$j].url")
            echo "contentUrl : $contentUrl"
            wget -c -q "$contentUrl"
        done 
    # VIDEOS
    elif [[ "$videosExist" != null ]]; then
        echo "[twitter] video found"
        contentType=$(echo "$tweetInfo" | jq -r '.video.contentType')
        if [[ "$contentType" == "gif" ]]; then
            src=$(echo "$tweetInfo" | jq -r ".video.variants[0].src")
            echo "$src"
            wget -c -q "$src"
        else
            for j in  $(echo "$tweetInfo" | jq -r '.video.variants | keys | .[]'); do
                type=$(echo "$tweetInfo" | jq -r ".video.variants[$j].type")
                if [[ "$type" == "application/x-mpegURL" ]]; then
                    src=$(echo "$tweetInfo" | jq -r ".video.variants[$j].src")
                    echo "$src"
                    ffmpeg -i "$src" -bsf:a aac_adtstoasc -vcodec copy -c copy -crf 50 "$tweetuser-$tweetid.mp4" 
                fi
            done 
        fi
    fi 
    cd ..
fi
