# ads

ads can cause a problem with the hls stream and decode.
therefore these ads need to be removed from final playlist.m3u8!

# idea

-   pull playlist.m3u8
-   remove ads programatically ad content from m3u8 file
-   use ffmpeg to download stream with file, tcp and https protocols

`https://stackoverflow.com/questions/50455695/why-does-ffmpeg-ignore-protocol-whitelist-flag-when-converting-https-m3u8-stream`
