# Twitter

## known issues
sometimes the response takes a bit to long/fails to often.
therefor the download breaks sometimes and you'd need to restart the download.

## how twitter works
you need two components to use a public twitter frontend timeline api
- guest token (gtg)
- the public static api key  
    `AAAAAAAAAAAAAAAAAAAAANRILgAAAAAAnNwIzUejRCOuH5E6I8xnZz4puTs%3D1Zv7ttfk8LF81IUq16cHjhLTvJu4FA33AGWWjCpTnA`

this info has been confirmed by research in webscraping forums afterwards.
therefore it's realatively certain that the key does not change regularly since it's been the same for years

## GTG
the guest token is embeded in the bottom of the page html

## the api url
there isn't really a point in chaninging the url params since the response seems to be equal `NtPJS7yopZTC4lPvb_kVEA` might be a query hash
note: this is not the latest request and maybe needs to be replaced soon
`https://twitter.com/i/api/graphql/NtPJS7yopZTC4lPvb_kVEA/TweetDetail?variables=%7B%22focalTweetId%22%3A%22${tweetid}%22%2C%22with_rux_injections%22%3Afalse%2C%22includePromotedContent%22%3Atrue%2C%22withCommunity%22%3Atrue%2C%22withQuickPromoteEligibilityTweetFields%22%3Afalse%2C%22withTweetQuoteCount%22%3Atrue%2C%22withBirdwatchNotes%22%3Afalse%2C%22withSuperFollowsUserFields%22%3Atrue%2C%22withUserResults%22%3Atrue%2C%22withNftAvatar%22%3Afalse%2C%22withBirdwatchPivots%22%3Afalse%2C%22withReactionsMetadata%22%3Afalse%2C%22withReactionsPerspective%22%3Afalse%2C%22withSuperFollowsTweetFields%22%3Atrue%2C%22withVoice%22%3Atrue%7D`

### what's in the response
there are medias in the response.
there also are audio medias as far as i know but there i couldn't find any example.
- photo
- video
- animated_gif

### path in the json
`.data.threaded_conversation_with_injections.instructions[0].entries[$i].content.itemContent.tweet_results.result.legacy.extended_entities`

`i` in this case is the number in the array of the tweet that matches our tweet id.
in the extended_entities we need to check how what media type we have in order to figure out which is the highest quality media to download.

### downloads
the download can be done with tools like wget without further headers since twitter does not restrict these.