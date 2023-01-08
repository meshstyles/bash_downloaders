# gofile

## create account api

`https://api.gofile.io/createAccount`

```bash
curl "https://api.gofile.io/createAccount" | jq '.data.token'
```

## verify token validity

`https://api.gofile.io/getAccountDetails?token=$token`  
if `.status` of the response is 'ok' then the token was valid.  
ideally the token gets saved to reduce the need to obtain new tokens which might look like unusual user behaviour.

## content api

we need to make an request with to the api with the following api params  
`https://api.gofile.io/getContent?contentId=$FOLDERID&token=$TOKEN&websiteToken=websiteToken`

contentId: $FOLDERID {string}  
token: $TOKEN {string}  
websiteToken: $websiteToken {string}

### websiteToken

is obtained via alljs.js and seems to be a constant number currently but it is dynamically obtained on the page itself.
For that reason I belive it's best to also get it dynamically to reduce the chance of the script breaking if the value changes.

### Whats important for file downloads

the link and name are required, if we obtain the name from the api object we can save ourselves parsing of the url.

```
.data.contents."UUID".link
.data.contents."UUID".name
```

### UUIDs

the UUIDs are required to access the links and names for files.  
the UUIDs are in the .data.childs array.

```
.data.childs[]
```
