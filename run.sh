cd /etc/nginx/conf.d

rm -rf config* test*

echo "$1" > config
echo "$2" > test

cat config
cat test

jq .config config | xargs echo -e > temp_config

cp default.conf default.conf.bak

cat temp_config | while read a; do if [[ ! $a = \#* ]]; then echo $a >> temp_delcomment; fi done
config=`cat temp_delcomment`
config="server{ rewrite_log on; listen 80; error_log /var/log/nginx/rewrite.log notice; ${config} }"
echo $config > default.conf

nginx

jq -r 'map(.|"wget -s http://127.0.0.1/"+.)[]' test > request.sh
chmod 755 request.sh
sh request.sh

log=$(cat /var/log/nginx/rewrite.log | while read line; do printf "$line\\\\n" | sed -e "s/\"/\\\\\"/g"; done)

echo "##START_RESULT##"
echo "{
    \"type\":\"STRING\",
    \"result\":{
        \"resultList\": [\"$log\"]
    }
}"
echo "##END_RESULT##"

rm -rf test* temp* config*
