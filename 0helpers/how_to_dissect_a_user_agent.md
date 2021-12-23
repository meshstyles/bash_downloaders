# on useragents

The most common useragent is chrome since most browsers are based on chrome.
On linux a lot of users would use firefox and on mac safari is still often used.
If you want to blend in use chrome but you could also try to boost alternative browser engine usage statistics.
Along with that you could send alternative operating system headers like mac os or linux.

To get a current useragent you can visit a site like [https://www.whatismybrowser.com/guides/the-latest-user-agent/](https://www.whatismybrowser.com/guides/the-latest-user-agent/)

# how to dissect a user agent

-   useragents for firefox contain `Firefox/`
-   useragents for chrome contain `Chrome/`
-   useragents for safari contain `Safari/`

To obtain each corresponding version for the browser you can split the string it on these values.
take the last part and split it on space.
than take the first part and trim the version number down as much as you need.

```bash
ua='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.45 Safari/537.36 OPR/82.0.4227.23'
ua_ver="${ua##*Chrome\/}"
ua_ver="${ua_ver%% *}"
echo "${ua_ver}"
```

the result of this snipt will be `96.0.4664.45`
