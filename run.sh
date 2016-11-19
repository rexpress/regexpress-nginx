# Move nginx config directory
cd /etc/nginx/conf.d

# Clean temporary file
rm -rf config* test*

# Arguments to file
echo "$1" | base64 -d > config
echo "$2" | base64 -d > test

# Save config to file without comments
jq .config config | xargs echo -e > temp_config
cat temp_config | while read a; do if [[ ! $a = \#* ]]; then echo $a >> temp_delcomment; fi done
config=`cat temp_delcomment`
config="server{ rewrite_log on; listen 80; error_log /var/log/nginx/rewrite.log notice; ${config} }"
echo $config > default.conf

# Start server
nginx

result=()

# Make http request shell and save rewrite log
jq -r '"wget http://127.0.0.1/"+map(.)[]+" \n result+=(\"$(cat /var/log/nginx/rewrite.log | while read -r line; do echo -n \"$line\\\\n\" | sed -e \"s/\\\\\\\"/\\\\\\\\\\\"/g\"; done )\") \n echo > /var/log/nginx/rewrite.log"' test > request.sh
chmod 755 request.sh
. request.sh

# Stop server
nginx -s stop

# Parse rewrite log to json
groups_list=
debug_output=

for((i=0; i < ${#result[@]}; i++));
 do
  debug_output+=${result[$i]}
  printf "${result[$i]}" > log
  rewritten=()
  while read -r line; do regex="rewritten data: \"([^\"]*).*args: \"([^\"]*)"; if [[ $line =~ $regex ]]; then rewritten+=("[\"${BASH_REMATCH[1]}\", \"${BASH_REMATCH[2]}\"]"); fi done < log
  groups="null"
  if [[ ${#rewritten[@]} -ne 0 ]];
    then
    groups="{\"list\":["
    for((j=0; j < ${#rewritten[@]}; j++));
     do 
      groups+="${rewritten[$j]}"
      if [[ $j -ne ${#rewritten[@]}-1 ]]; 
       then
       groups+=","
      fi
    done
    groups+="]}"
  fi
  
  groups_list+="$groups"
  if [[ $i -ne ${#result[@]}-1 ]];
   then
   groups_list+=","
  fi
done

# Print result json
echo "##START_RESULT##"
echo "{
    \"type\":\"GROUP\",
    \"result\":{
        \"columns\":[\"Rewritten URL\", \"Parameter\"], 
        \"resultList\": [
             $groups_list
        ]
    },
    \"debugOutput\": \"$debug_output\"
}"
echo "##END_RESULT##"

# Clean temporary file
rm -rf test* temp* config*
