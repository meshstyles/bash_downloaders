# understand website

## req path

    - first page load
    - obtaining stream token via gql
    - obtaining and analysing info gql api [optional]
    - obtaining hls main stream
    - obtaining hls daughter stream

## download

    - checking if stream might have drm according to info gql [optional]
    - selecting daughter stream from main stream
    - using ffmpeg just download the hls
    - ffmpeg auto stops download on stream end

# token gql api

## http-req params

-   client-id is obtained via main page
-   device id is randomly generated 32-alphanumeric

# playback api

## url params

```
-> allow_source=true
-> fast_bread=true
p=${p_number}
play_session_id=${play_id}
-> player_backend=mediaplayer
-> playlist_include_framerate=true
-> reassignments_supported=true
sig=${signatrue}
-> supported_codecs=avc1
token=${playbacktoken}
-> cdm=wv
player_version=$playerversion
```

## need to be dynamically obtained

-   p ???????? [optional] [7 char long number]
-   play_session_id [optional] [32 char b64]
-   token via token gql api
-   signature via token gql api
-   player version `https://static.twitchcdn.net/assets/player-core-variant-a-${playerid}.js`

    -   url static except id
    -   id is in main page html in a json `5e3:${id}`
