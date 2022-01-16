#!/bin/bash

link="${1}"
useragent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.45 Safari/537.36 OPR/82.0.4227.23"

#link "pluto.tv/"
#cutoff

sample_client_id="8d97a90b-b33f-41ba-$(date +%M%S)-de64186dd3db"
appversion='5.106.0-f3e2ac48d1dbe8189dc784777108b725b4be6be2'

func_alternative_name(){
    # this solves issues with naming
    echo "waiting for name api"
    sleep 1

    alternative_name=$(curl 'https://service-stitcher-ipv4.clusters.pluto.tv/v2/session.json' \
    -H 'authority: service-stitcher-ipv4.clusters.pluto.tv' \
    -H "authorization: Bearer ${jwt}" \
    -H 'sec-ch-ua-mobile: ?0' \
    -H "user-agent: ${useragent}" \
    -H 'sec-ch-ua-platform: "Windows"' \
    -H 'accept: */*' \
    -H 'origin: https://pluto.tv' \
    -H 'sec-fetch-site: same-site' \
    -H 'sec-fetch-mode: cors' \
    -H 'sec-fetch-dest: empty' \
    -H 'referer: https://pluto.tv/' \
    -H 'accept-language: de-DE,de;q=0.9,en-US;q=0.8,en;q=0.7,zh-CN;q=0.6,zh;q=0.5' \
    --compressed | jq -r '.clips[0].name') 

    alternative_name=$(echo "$alternative_name" | sed "s/[:/|]/-/g; s/%20/ /g; s/ $//; s/&amp;/\&/g")
    echo "using alternative name supplied by website: $alternative_name"
}

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

    # obtaining page data like the appversion needed for start
    page=$( curl "$link" \
        -H 'sec-ch-ua-mobile: ?0' \
        -H 'sec-ch-ua-platform: "Windows"' \
        -H 'Upgrade-Insecure-Requests: 1' \
        -H "User-Agent: $useragent")
        
    appversion=$(echo "$page" | pup 'meta[name="appVersion"] attr{content}')
    echo "appversion : $appversion"

    useragent_ver="${useragent_ver%% *}"
    appName="web"
    deviceModel="web"
    deviceType="web"
    clientModelNumber="1.0.0"
    # there is no diffrence when false or true the server returns a stream with ads
    serverSideAds="true"
    constraints=""

    used_client_id="$sample_client_id"
    echo "client_id : ${used_client_id}"

    # clientDate="$(date +%Y)-$(date +%m)-$(date +%d)T$(date +%H):$(date +%M):$(date +%S).$(date +%S)1T"
    clientDate="$(date +%Y-%m-%dT%H:%M:%S.%S)1T"

    # this is bad style but makes it easier to compare to a real url in an editor window
    starturl="https://boot.pluto.tv/v4/start?appName=${appName}&appVersion=${appversion}&deviceVersion=${useragent_ver}&deviceModel=${deviceModel}&deviceMake=${deviceMake}&deviceType=${deviceType}&clientID=${used_client_id}&clientModelNumber=${clientModelNumber}&${stream_type}=${slug}&serverSideAds=${serverSideAds}&constraints=${constraints}&clientTime=${clientDate}"

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
    # echo $start > start.json
    # these are variables used to obtain master.m3u8 or playlist.m3u8
    baseurl_hls=$(echo "$start" | jq -r '.servers.stitcher')
    JWTPassthrough="true"
    jwt=$(echo "$start" | jq -r '.sessionToken')
    vod_prams=$(echo "$start" | jq -r '.stitcherParams' | sed 's/\\u0026/\&/g')

}

func_download_from_hls(){
        
    vod_req_url="${baseurl_hls}${vod_url}?${vod_prams}&jwt=${jwt}&masterJWTPassthrough=${JWTPassthrough}"

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

    playlist_req_url="${baseurl_hls}${baseurl_playlist}${playlist_url}"

    echo "$playlist_req_url"

    if [[ "$link" == *'/live-tv/'* ]]; then
        ffmpeg -i "${playlist_req_url}" \
        -headers 'authority: service-stitcher-ipv4.clusters.pluto.tv' \
        -headers 'sec-ch-ua-mobile: ?0' \
        -headers "user-agent: ${useragent}" \
        -headers 'sec-ch-ua-platform: "Windows"' \
        -headers 'accept: _/_' \
        -headers 'origin: https://pluto.tv' \
        -headers 'sec-fetch-site: same-site' \
        -headers 'sec-fetch-mode: cors' \
        -headers 'sec-fetch-dest: empty' \
        -headers 'referer: https://pluto.tv/' \
        -headers 'accept-language: de-DE,de;q=0.9,en-US;q=0.8,en;q=0.7,zh-CN;q=0.6,zh;q=0.5' \
        -bsf:a aac_adtstoasc -vcodec copy -c copy -crf 50 "rec-${slug}-$(date +%s).mp4"
    else
        # using alternative naming for seriess if available
        # this needs to be done here since the hls needs to be obtained first
        if [[  "$link" == *'/series/'* ]]; then 
            # obtain alternative episode name
            func_alternative_name
            # if we end in ) then there was a result otherwise fall back
            if [[ "$alternative_name" == *')' ]]; then
                vod_name="$alternative_name"
            fi
        fi
        # we have on demand content so we can download playlist and than use ffmpeg
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

    fi
}

if [[ "$link" == *'/search/details/'* ]]; then 
    
    if [[ "$link" == *'/channels/pluto-tv-'* ]]; then 
        link=$(echo "$link" | sed 's/search\/details\/channels/live-tv/')
        echo "$link"
    else
        link=$(echo "$link" | sed 's/search/on-demand/')
        echo "$link"
    fi
    
fi

if [[ "$link" == *'/on-demand/'* ]]; then 
    echo "this is on-demand content"
    # this is the way on demand content declared
    stream_type="episodeSlugs"

    if [[ "$link" == *'/series/'* ]]; then
        echo "it's a series"

        slug="${link##*\/series\/}"
        slug="${slug%%\/*}"
        slug="${slug%%\?*}"

        season_number="${link##*\/season\/}"
        season_number="${season_number%%\/*}"
        season_number="${season_number%%\?*}"

        # on entire season
        # use this to check back with ".VOD[0].seasons[j].number" to see if guessed i-1 was correct otherwise loop

        if [[ "$season_number" =~ ^[0-9]+$ ]]; then
            echo "season nummber : $season_number"
        else
            season_number=""
        fi

        # entire show and exit
        if [[ "$season_number" == "" ]]; then
            echo "download it all?"
            echo "this would download every episode of the ENTIRE show "
            echo "type \"yes\" if you want to attempt to download eveything"
            
            read user_download_all_seasons

            if [[ "$user_download_all_seasons" == "yes" ]]; then

                func_setup
                # make a folder for the series to keep order
                mkdir "$slug"
                cd "$slug"

                for season_index in $(jq -r '.VOD[0].seasons | keys | .[]' <<< "$start"); do

                    # set season number once per season
                    season_number_info=$(echo "$start" | jq -r ".VOD[0].seasons[$season_index].number")
                    season_number_adjusted=$(echo $season_number_info | awk '/^([0-9]+)$/ { printf("%02d", $0) }')
                    # make folder for season so content is sorted
                    mkdir "Season-$season_number_info"
                    cd "Season-$season_number_info"

                    for episode_index in $(jq -r ".VOD[0].seasons[$season_index].episodes | keys | .[]" <<< "$start"); do
                        vod_url=$(echo "$start" | jq -r ".VOD[0].seasons[$season_index].episodes[$episode_index].stitched.path")
                        vod_name=$(echo "$start" | jq -r ".VOD[0].seasons[$season_index].episodes[$episode_index].name" | sed "s/[:/|]/-/g; s/%20/ /g; s/ $//; s/&amp;/\&/g")
                        episode_number_adjusted=$(echo $(( episode_index + 1 )) | awk '/^([0-9]+)$/ { printf("%03d", $0) }')
                        vod_name="S${season_number_adjusted}E${episode_number_adjusted}-${vod_name}"

                        echo "====================================="
                        echo $vod_name
                        echo $vod_url
                        echo "====================================="


                        # this should run every or every other episode to
                        # please remember to comment func_setup while developing
                        # always update the jwt since it's only good for 6hrs and downloads can take time
                        func_download_from_hls
                        func_setup

                    done
                    
                    # go back out so the seasons are not nested
                    cd ..

                done

            fi

            exit 0
        fi

        episode_name="${link##*\/episode\/}"
        episode_name="${episode_name%%\/*}"
        episode_name="${episode_name%%\?*}"

        # on sinlge episodes
        # use this to check with ".VOD[0].seasons[0].episodes[j].slug" to see if guess i-1 was correct otherwise loop

        # if therer is no /episode/ in the link we have a season link
        if [[ "$link" != *"/episode/"* ]]; then
            episode_name=""
        else
            echo "episode name : $episode_name"
        fi

        # initial start json is obtained
        func_setup
        
        # obtain season index
        season_number_adjusted="$(( season_number - 1 ))"
        season_number_obtained=$(echo "$start" | jq -r ".VOD[0].seasons[$season_number_adjusted].number")
        
        if [[ "$season_number_obtained" != "$season_number"  ]]; then
            echo "should be $season_number"
            echo "obtained $season_number_obtained"
            
            for season_index in $(jq -r '.VOD[0].seasons | keys | .[]' <<< "$start"); do
                season_number_info=$(echo "$start" | jq -r ".VOD[0].seasons[$season_index].number")
                if [[ "$season_number_info" == "$season_number"  ]]; then
                    season_number_index="$season_index"
                    echo "the real index: $season_index"
                    break
                fi
            done
            season_index="$season_number_index"
        else
            season_index="$season_number_adjusted"
        fi

        # entire seasons
        if [[ "$episode_name" == "" ]]; then
            echo "download it all?"
            echo "this would download every episode of season $season_number"
            echo "type \"yes\" if you want to attempt to download this season"
            
            read user_download_all_seasons

            if [[ "$user_download_all_seasons" == "yes" ]]; then
                
                # make a folder for the series to keep order
                mkdir "$slug"
                cd "$slug"

                # make folder for season so content is sorted
                mkdir "Season-${season_number}"
                cd "Season-${season_number}"

                for episode_index in $(jq -r ".VOD[0].seasons[$season_index].episodes | keys | .[]" <<< "$start"); do
                    vod_url=$(echo "$start" | jq -r ".VOD[0].seasons[$season_index].episodes[$episode_index].stitched.path")
                    vod_name=$(echo "$start" | jq -r ".VOD[0].seasons[$season_index].episodes[$episode_index].name" | sed "s/[:/|]/-/g; s/%20/ /g; s/ $//; s/&amp;/\&/g")
                    episode_number_adjusted=$(echo $(( episode_index + 1 )) | awk '/^([0-9]+)$/ { printf("%03d", $0) }')
                    vod_name="S${season_number}E${episode_number_adjusted}-${vod_name}"

                    # please remember to comment func_setup while developing
                    echo "====================================="
                    echo $vod_name
                    echo $vod_url
                    echo "====================================="

                    # this should run every or every other episode to
                    # always update the jwt since it's only good for 6hrs and downloads can take time
                    func_download_from_hls
                    
                    func_setup

                done
            fi

        # single episode
        else

            echo $episode_name
            episode_index=$(echo "$episode_name" | rev | cut -d '-' -f 1 | rev)
            episode_index="$(( episode_index - 1 ))"

            echo "assumed index $episode_index"
            echo "we obtained season number $season_index"
        
            # downloading a single episode
            episode_index_slug=$(echo "$start" | jq -r ".VOD[0].seasons[$season_index].episodes[$episode_index].slug" )
            if [[ "$episode_name" != "$episode_index_slug" ]]; then
                for episode_index_loop in $(jq -r ".VOD[0].seasons[$season_index].episodes | keys | .[]" <<< "$start"); do
                    index_slug=$(echo "$start" | jq -r ".VOD[0].seasons[$season_index].episodes[$episode_index_loop].slug")
                    # echo "-$index_slug-"
                    echo "we obtained season number $season_index"
                    echo "$episode_index_loop"
                    if [[ "$episode_name" == "$index_slug" ]]; then
                        episode_index="$episode_index_loop"
                        echo "found index $episode_index_loop"
                        echo "found slug : $index_slug"
                        break
                    fi
                done
            fi

            vod_name=$(echo "$start" | jq -r ".VOD[0].seasons[$season_index].episodes[$episode_index].name" | sed "s/[:/|]/-/g; s/%20/ /g; s/ $//; s/&amp;/\&/g")
            vod_url=$(echo "$start" | jq -r ".VOD[0].seasons[$season_index].episodes[$episode_index].stitched.path")

            # naming episode
            season_number_adjusted=$(echo $(( season_index + 1 )) | awk '/^([0-9]+)$/ { printf("%02d", $0) }')
            episode_number_adjusted=$(echo $(( episode_index + 1 )) | awk '/^([0-9]+)$/ { printf("%03d", $0) }')
            vod_name="S${season_number_adjusted}E${episode_number_adjusted}-${vod_name}"

            echo "====================================="
            echo $vod_name
            echo $vod_url
            echo "====================================="

            func_download_from_hls

        fi

        exit 0

    elif [[ "$link" == *'/movies/'* ]]; then
        echo "it's a movie"
        
        slug="${link##*\/movies\/}"
        slug="${slug%%\/*}"
        slug="${slug%%\?*}"

        # func_setup now also obtains the curl of start api and setup of common variables 
        func_setup
        
        # ATTENTION: this is a movie so this will always be the first stream w/o season
        vod_url=$(echo "$start" | jq -r '.VOD[0].stitched.path')
        vod_name=$(echo "$start" | jq -r '.VOD[0].name' | sed "s/[:/|]/-/g; s/%20/ /g; s/ $//; s/&amp;/\&/g")

        func_download_from_hls
        exit 0

    else
        # undocumented content types
        echo "this kind of on-demand content is currently not supported."
        echo "if you know how it works; please contribute -> https://github.com/meshstyles/bash_downloaders"
        exit 1
    fi

elif [[ "$link" == *'/live-tv/'* ]]; then 
    # this is the way on "live" content declared
    stream_type="channelSlug"
    echo "this is a live-playback in the channel ${slug}"
    echo "recodings go from when you start until you end ( with crtl+c )"
    echo "you're watching $link"

    slug="${link##*\/live-tv\/}"
    slug="${slug%%\/*}"
    slug="${slug%%\?*}"

    func_setup

    vod_url=$(echo "$start" | jq -r '.EPG[0].stitched.path')

    func_download_from_hls

    exit 0
fi