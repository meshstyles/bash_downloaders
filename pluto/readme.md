# usage

## movies

`./script "linktomovie"`

## single episode of a show

`./script "linktoepisode"`

### sample link

`https://pluto.tv/on-demand/series/$series-slug/season/$season-number/episode/$episode-slug`
NOTE: the link must end in something like `-1-22.`  
This repersents season 1 episode 22. otherwise the script won't work.

## shows

attention: naming for shows has been changed to be exactly what the site tells you it is.

## single season of a show

`./script "linktomovie"`

### sample link

`https://pluto.tv/on-demand/series/$series-slug/season/$season-number/`
NOTE: At least the season number must be included and the episode name must be missing.

# everything available of a show

`./script "linktomovie"`

### sample link

`https://pluto.tv/on-demand/series/$series-slug/details`
NOTE: At least the series name must be included and the season number must be missing.

## live-tv

this just records ongoing live as long as it runs.
i'm no expert on ffmpeg but the stream will be written to disc once you end the recording.
to end a recording just press [ctrl]+[c].
the name will be the name of the channel (slug-> that's the thing in the url)
you will need to supply the url to the channel with that slug and make sure it's in there and not just the main url.
