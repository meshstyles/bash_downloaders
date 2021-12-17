#!/bin/bash
link="${1}"

#link "netzkino.de/filme"
#cutoff
page=$(curl "$link")
pmdext=$(echo "$page" | pup 'script#__NEXT_DATA__ text{}' | jq '.' | grep 'pmdUrl' | cut -d '"' -f 4)
echo $pmdext
wget -c "https://pmd.netzkino-seite.netzkino.de/${pmdext}" || exit 1
exit 0