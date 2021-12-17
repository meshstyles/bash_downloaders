# video download curl

-   csrf token optional
    -   ther is no reaso for this to be optional but why obtain if you don't need it
-   the user agent change to a "normal browser" like firefox is optional
-   referer must be set tiktok.com

```bash
curl 'https://v16-web.tiktok.com/video/tos/useast2a/tos-useast2a-pve-0068/........' \
  -H 'Connection: keep-alive' \
  -H 'sec-ch-ua: "Chromium";v="96", "Opera";v="82", ";Not A Brand";v="99"' \
  -H 'sec-ch-ua-mobile: ?0' \
  -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.45 Safari/537.36 OPR/82.0.4227.23' \
  -H 'sec-ch-ua-platform: "Windows"' \
  -H 'Accept: */*' \
  -H 'Sec-Fetch-Site: same-site' \
  -H 'Sec-Fetch-Mode: no-cors' \
  -H 'Sec-Fetch-Dest: video' \
  -H 'Referer: https://www.tiktok.com/' \
  -H 'Accept-Language: en-US;q=0.8,en;q=0.7' \
  --compressed
```

# website

## unauthed url

`https://www.tiktok.com/@user/video/123456789123456`

-   needs browser header does not support curl

## user share url

`https://vm.tiktok.com/someid/`

-   needs browser header does not support curl
-   does resolve to incomplete dom
-   contains only a tag with href to "actual" page
    -   pup path : a attr{href}

## mobile website

`https://m.tiktok.com/v/123456789123456.html`

-   username needs to be extacted from page
-

curl 'https://www.tiktok.com/@user/video/123456789123456?lang=en-US&is_copy_url=1&is_from_webapp=v1' \
 -H 'authority: www.tiktok.com' \
 -H 'cache-control: max-age=0' \
 -H 'sec-ch-ua: "Chromium";v="96", "Opera";v="82", ";Not A Brand";v="99"' \
 -H 'sec-ch-ua-mobile: ?0' \
 -H 'sec-ch-ua-platform: "Windows"' \
 -H 'upgrade-insecure-requests: 1' \
 -H 'user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.45 Safari/537.36 OPR/82.0.4227.23' \
 -H 'accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,_/_;q=0.8,application/signed-exchange;v=b3;q=0.9' \
 -H 'sec-fetch-site: none' \
 -H 'sec-fetch-mode: navigate' \
 -H 'sec-fetch-user: ?1' \
 -H 'sec-fetch-dest: document' \
 -H 'accept-language: en-US;q=0.8,en;q=0.7' \
 --compressed
