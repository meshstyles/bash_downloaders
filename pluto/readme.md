# usage

## movies
`./script "linktomovie"`

## single episode of a show
`./script "linktoepisode"`
### sample link
`https://pluto.tv/on-demand/series/$series-slug/season/$season-number/episode/$episode-slug`
NOTE: the link must end in something like `-1-22.`  
This repersents season 1 episode 22. otherwise the script won't work.

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
