# gofile

## create account api

`https://api.gofile.io/createAccount`

```bash
curl "https://api.gofile.io/createAccount" | jq '.data.token'
```

## content api

we need to make an request with to the api with the following api params  
`https://api.gofile.io/getContent?contentFilter=&page=1&pageSize=1000&sortField=name&sortDirection=1`

I've not found an upload with more than 1k files so that is the current max limit of sequential downloads

contentId: $FOLDERID {string}  
token: $TOKEN {string}  
websiteToken: $websiteToken {string}

### websiteToken

is obtained via config.js and seems to be a semi constant string but it is dynamically obtained on the page itself.
For that reason I belive it's best to also get it dynamically to reduce the chance of the script breaking if the value changes.

### continued download

I've made the choice to remove the questing on if a user wants to continue to not block when running in a script. I've also added `-C -` to the curl command to not having to start from a fresh file and loosing previous download progress.
