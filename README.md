# bash_downloaders

these are several downloaders written in bash

## how to use this

1. take a look at the releases tab
2. download the script
3. read the script or build it yourself from modules
4. make it runnable for example with `chmod 700 media_dl.sh`
5. run it with `./media_dl.sh "link_to_supported_website"`

## how to build

run `./build.sh` in the main directory of the repository

## dependencies

please add dependencies here as you go

-   pup
-   jq
-   curl
-   wget
-   bash
-   more gnu/linux tools you should already have installed

## supported pages

-   tiktok (direct video link only)
-   netzkino.de (several types of movies)

## how to develop extensions

-   create a new folder
-   create a `script.sh` in that folder
-   create a self contained download script here that follows the following specifications
    -   the script should only need one argument which is the link to the content
    -   the link used in the downloader is a variable called `link`
    -   if a useragent is user it should be a variable called `useragent`
    -   there needs to be a url for which the module supports. it needs to be only one link.
    -   the link should be denoted like `#link "url.domain/"` or `#link "url.domain/videos"`
    -   set up link, useragent and the applicable link filter in your self contained script before `#cutoff`
    -   after `#cutoff` should the fully working and fully self contained part which only rely on `link` and `useragent`
-   create a new branch and put in a pull request if you want to contribute

## upcoming

-   a better readme
