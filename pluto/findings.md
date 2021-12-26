# PLUTO

## How does the site work

-   there is curated video streaming part and on demand (we'll focus entirely on on demand)
-   there are shows and movies
-   the show and movies are identifies via slugs
-   there is a an api (/v4/start) which contains the hls partial urls and jwt

## what data is needed

-   show url
-   useragent
    -   broswer type
    -   broswer version
-   client time and date? > can be arbitrary
-   jwt from /v4/start
-   appVersion from the index.html
-   clientID => can be semi arbitrary and is calculated out of cookie data / is decided once

# /v4/start

-   VOD Downloads
    -   Movie 'VOD[0].stitched.path'
-   VOD Params
    -   'stitcherParams'
-   Token
    -   'sessionToken'

## obtaining master.m3u8

-   if ip-v4 then we need service-stitcher-ipv4. as prefix
-   look for the highest bitrate possible

### url arguments

ATTENTION: these params should be in preassembled in the /v4/start json.
The only thing missing should be the jwt variable and jwtpassthrough.

will keep the findings regardless

-   advertisingId= => is left empty by default
-   appName=web
-   appVersion from the index.html
-   app_name=web
-   clientDeviceType=0
-   clientID= => see above
-   clientModelNumber=1.0.0
-   country=DE => need to set from domain
-   deviceDNT=false
-   deviceId= the same as clientID
-   deviceLat= => need to be calcualted from locale
-   deviceLon= => need to be calcualted from locale
-   deviceMake= => browser name from useragent
-   deviceModel=web
-   deviceType=web
-   deviceVersion= => version of the browser
-   marketingRegion=DE => need to set from domain
-   serverSideAds=true
-   sessionID= => can be left empty
-   sid= => can be left empty
-   userId= => is left empty by default
-   resumeAt=0
-   eventVOD=true =>
-   jwt= => from /v4/start
-   masterJWTPassthrough=true

## playlist.m3u8

-   this is obtained via master.m3u8
-   contains the actual hls stream
-   remove ads to avoid stream continuity issues
-   use local hls file to as the fixed m3u8 file
-   use ffmpeg to download and convert the hls
    -   using these options to accept local file as source (copied from stackoverflow) `-protocol_whitelist file,http,https,tcp,tls,crypto -i "./playlist.m3u8"`
    -   possibly could do without http

## ISSUES

### Black screen / doesn't play

If the video you have downloaded has a black screen/ doesn't the video might have drm.
This downloader doesn't break drm, and doesn't plan on breaking drm.
Some of the videos on pluto in america may be available on other sites w/o drm.
These sites are all supported by youtube-dl

This downloader also just encourages to obtain a local copy for offline; followed by deltion of the file
or download for archival purpose.
Please obtain an original copy of the media.
