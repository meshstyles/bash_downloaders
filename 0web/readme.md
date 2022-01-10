# Webversion Home Ed.

This is a simple frontend to use cgi to remotely run the bash script through a webrequest.
This script does not employ user input sanitation and this may lead to an entry point.
DO NOT RUN THIS ON A SERVER EXPOSED TO THE INTERNET!

## who is this for?

anyone who doesn't want to ssh into their raspberry pi or local home only server.

## who is this not for?

anyone who's server is port forwarded as in exposed to the internet where this site could be accesible.
I personally DO NOT recomend just trying to hide this behind apache basic auth!

## how to use it?

All you need to do is enable the apache cgi or cgid module.
place the content of intranet.tar into a folder on your apache server and it should work.
