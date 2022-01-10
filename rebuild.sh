#!/bin/bash

buildmodule(){
    cd "$module"
    if [ -f script.sh ] ; then 
        url=$(grep "#link " "script.sh")
        url=$(echo "${url##*link \"}" | cut -d \" -f 1)
        
        echo $url

cat >> "../media_dl.sh" <<- EOM
#####################################
#  $url
#####################################
EOM

cat >> "../0web/media_dl_srv.sh" <<- EOM
#####################################
#  $url
#####################################
EOM

        echo "if [[ \"\$link\" == *\"$url\"* ]] ; then " | tee -a ../media_dl.sh ../0web/media_dl_srv.sh

        module_script=$(cat script.sh | sed -e 's/^/    /')
        module_script="${module_script##*\#cutoff}"

        echo "$module_script" | tee -a ../media_dl.sh ../0web/media_dl_srv.sh
        echo "fi" | tee -a ../media_dl.sh ../0web/media_dl_srv.sh
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

cat > "0web/media_dl_srv.sh" <<- EOM
#!/bin/bash

echo "Content-type: text/plain"
echo ''

link="\${QUERY_STRING##*link=}"
useragent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.45 Safari/537.36 OPR/82.0.4227.23"

app_dir="\$(pwd)"
activivelist="\${app_dir}/activelist"

echo "\$link" >> "\$activivelist"

cd "\$app_dir/downloads"
tmpfile="/tmp/\$(date +%s)tempfile.active"

EOM

module_list="./module.list"
while IFS= read -r module
do
    buildmodule
done <"$module_list"

rm module.list

echo "# remove from active list" >> 0web/media_dl_srv.sh
echo "grep -v \"\$link\" \"\$activivelist\" > \"\$tmpfile\" ; mv \"\$tmpfile\" \"\$activivelist\" " >> 0web/media_dl_srv.sh

dos2unix media_dl.sh
dos2unix 0web/media_dl_srv.sh

cd 0web
chmod 755 media_dl_srv.sh
tar -cvf ../intranet.tar activelist .htaccess downloads/ index.html media_dl_srv.sh
cd ..

mkdir 0releases
mv intranet.tar 0releases/
mv media_dl.sh 0releases/
