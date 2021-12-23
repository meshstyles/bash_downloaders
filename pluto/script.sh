#!/bin/bash

link="${1}"
useragent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.45 Safari/537.36 OPR/82.0.4227.23"

#link "pluto.tv/"
#cutoff
if [[ "$link" == *'/on-demand/'* ]]; then 
    
    func_setup(){
        # safari needs to be below chrome in order to no trigger the if else if ..
        if [[ "$useragent" == *'Chrome/'* ]]; then
            useragent_ver="${useragent##*Chrome\/}"
            deviceMake="chrome"

        elif [[ "$useragent" == *'Firefox/'* ]]; then
            useragent_ver="${useragent##*Chrome\/}"
            deviceMake="firefox"

        elif [[ "$useragent" == *'Safari/'* ]]; then
            useragent_ver="${useragent##*Chrome\/}"
            deviceMake="safari"

        else
            echo "this browseragent is not supported"
            echo "so we're going to use some of hard coded variables"
            useragent_ver="96.0.4664"
            deviceMake="chrome"
        fi

        useragent_ver="${useragent_ver%% *}"
        appName="web"
        deviceModel="web"
        deviceType="web"
        clientModelNumber="1.0.0"
        serverSideAds="true"
        constraints=""

        sample_client_id="8d97a90b-b33f-41ba-1337-de64186dd3db"

        clientDate="$(date +%Y)-$(date +%m)-$(date +%d)T$(date +%H):$(date +%M):$(date +%S).$(date +%S)1T"

        # this is bad style but makes it easier to compare to
        # a real url in an editor window
        starturl="https://boot.pluto.tv/v4/start?appName=${appName}&appVersion=${appversion}&deviceVersion=${useragent_ver}&deviceModel=${deviceModel}&deviceMake=${deviceMake}&deviceType=${deviceType}&clientID=${sample_client_id}&clientModelNumber=${clientModelNumber}&episodeSlugs=${slug}&serverSideAds=${serverSideAds}&constraints=${constraints}&clientTime=${clientDate}"
    }

    page=$( curl "$link" \
    -H 'sec-ch-ua-mobile: ?0' \
    -H 'sec-ch-ua-platform: "Windows"' \
    -H 'Upgrade-Insecure-Requests: 1' \
    -H "User-Agent: $useragent")
    
    appversion=$(echo "$page" | pup 'meta[name="appVersion"] attr{content}')

    # get the variables for next request

    echo "appversion : $appversion"
    # appversion="5.106.0-f3e2ac48d1dbe8189dc784777108b725b4be6be2"
    # echo "appversion : $appversion"

    if [[ "$link" == *'/series/'* ]]; then
        echo "it's a series"
        echo "series are currently not supported. But it's being worked on "
        echo "if you know how it works; please contribute -> https://github.com/meshstyles/bash_downloaders"
        exit 1

        slug="${link##*\/series\/}"
        slug="${slug%%\/*}"
        func_setup

    elif [[ "$link" == *'/movies/'* ]]; then
        echo "it's a movie"
        
        slug="${link##*\/movies\/}"
        slug="${slug%%\/*}"

        func_setup

        start=$(curl "$starturl" \
            -H 'authority: boot.pluto.tv' \
            -H 'sec-ch-ua-mobile: ?0' \
            -H "user-agent: ${useragent}" \
            -H 'accept: */*' \
            -H 'origin: https://pluto.tv' \
            -H 'sec-fetch-site: same-site' \
            -H 'sec-fetch-mode: cors' \
            -H 'sec-fetch-dest: empty' \
            -H 'referer: https://pluto.tv/' \
            -H 'accept-language: en-US;q=0.8,en;q=0.7' \
            --compressed )

        # use this to debug
        # echo "$start" > start.json

        baseurl_hls="https://service-stitcher-ipv4.clusters.pluto.tv/v2"
        JWTPassthrough="true"
        # ATTENTION: this is a movie so this will always be the first stream w/o season
        vod_url=$(echo "$start" | jq -r '.VOD[0].stitched.path')
        vod_name=$(echo "$start" | jq -r '.VOD[0].name' | sed "s/[:/|]/-/g; s/%20/ /g; s/ $//; s/&amp;/\&/g")
        vod_prams=$(echo "$start" | jq -r '.stitcherParams' | sed 's/\\u0026/\&/g')
        jwt=$(echo "$start" | jq -r '.sessionToken')

        vod_req_url="${baseurl_hls}${vod_url}?${vod_prams}&&jwt=${jwt}&masterJWTPassthrough=${JWTPassthrough}"

        master_hls=$(curl "$vod_req_url" \
            -H 'authority: service-stitcher-ipv4.clusters.pluto.tv' \
            -H 'sec-ch-ua-mobile: ?0' \
            -H "user-agent: ${useragent}" \
            -H 'accept: */*' \
            -H 'origin: https://pluto.tv' \
            -H 'sec-fetch-site: same-site' \
            -H 'sec-fetch-mode: cors' \
            -H 'sec-fetch-dest: empty' \
            -H 'referer: https://pluto.tv/' \
            -H 'accept-language: en-US;q=0.8,en;q=0.7' \
            --compressed )

        # use this to debug
        # echo "$master_hls" > master.m3u8
        
        list_of_res=$( echo "$master_hls" | grep "BANDWIDTH=" | sed 's/#EXT-X-STREAM-INF:PROGRAM-ID=1,BANDWIDTH=//g' | cut -d ',' -f 1)
        array_of_res=($list_of_res)
        max_res=0
        for res in "${array_of_res[@]}"
        do

            if [ "$res" -gt "$max_res" ]; then
                max_res="$res"
            fi
        done

        playlist_url=$(echo "$master_hls" | grep "$max_res/playlist")
        baseurl_playlist=${vod_url%%master.m3u8*}

        #TODO finish this
        playlist_req_url="${baseurl_hls}${baseurl_playlist}${playlist_url}"

        echo "$playlist_req_url"

        playlist_hls_file="playlist_$(date +%s).m3u8"

        playlist_hls=$(curl "$playlist_req_url" \
            -H 'authority: service-stitcher-ipv4.clusters.pluto.tv' \
            -H 'sec-ch-ua-mobile: ?0' \
            -H "user-agent: ${useragent}" \
            -H 'sec-ch-ua-platform: "Windows"' \
            -H 'accept: _/_' \
            -H 'origin: https://pluto.tv' \
            -H 'sec-fetch-site: same-site' \
            -H 'sec-fetch-mode: cors' \
            -H 'sec-fetch-dest: empty' \
            -H 'referer: https://pluto.tv/' \
            -H 'accept-language: de-DE,de;q=0.9,en-US;q=0.8,en;q=0.7,zh-CN;q=0.6,zh;q=0.5' \
            --compressed)

        echo "$playlist_hls" | grep -v -e '/creative/\|Pluto_TV_OandO/clip' | grep -v -e '#EXT-X-DISCONTINUITY\|#EXT-X-PROGRAM-DATE-TIME' > "$playlist_hls_file"

        ffmpeg -protocol_whitelist file,http,https,tcp,tls,crypto -i "$playlist_hls_file" -bsf:a aac_adtstoasc -vcodec copy -c copy -crf 50 "${vod_name}.mp4"
        
        rm "$playlist_hls_file"

        exit 0;
    else
        echo "this kind of on-demand content is currently not supported."
        echo "if you know how it works; please contribute -> https://github.com/meshstyles/bash_downloaders"
        exit 1
    fi

else
    echo "steams are currently not supported."
    echo "if you know how it works; please contribute -> https://github.com/meshstyles/bash_downloaders"
    exit 1
fi