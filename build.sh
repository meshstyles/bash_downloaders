#!/bin/bash

buildmodule(){
    cd "$module"
    if [ -f script.sh ] ; then 
        url=$(grep "#link " "script.sh")
        url=$(echo "${url##*link \"}" | cut -d \" -f 1)
        echo "if [[ \"\$link\" == *\"$url\"* ]] ; then " >> ../media_dl.sh
        echo $url

        module_script=$(cat script.sh)
        module_script="${module_script##*\#cutoff}"
        echo "$module_script" >> ../media_dl.sh
        echo "fi" >> ../media_dl.sh

        cd ..
    else
        cd ..
    fi
}


ls -d */ > module.list

cat > "media_dl.sh" <<- EOM
#!/bin/bash

link="\${1}"
useragent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.45 Safari/537.36 OPR/82.0.4227.23"

EOM

module_list="./module.list"
while IFS= read -r module
do
    buildmodule
done <"$module_list"

rm module.list