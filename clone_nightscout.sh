#!/bin/bash  

clone_collection() {
   REST_ENDPOINT=$1
   collection_name=$2
   read_token=$3
   echo $REST_ENDPOINT
   if [[ $collection_name == entries ]]; then
       wget $REST_ENDPOINT/api/v1/$collection_name'.json?find[date][$gte]=1662845659&count=1000000'$read_token -O /tmp/$collection_name.json 
   else
       wget $REST_ENDPOINT/api/v1/$collection_name'.json?find[created_at][$gte]=1662845659&count=1000000'$read_token -O /tmp/$collection_name.json
   fi
   jq '.[]' /tmp/$collection_name.json > /tmp/$collection_name.jq.json 
   mongoimport --uri "mongodb://username:password@localhost:27017/Nightscout" --mode=upsert --collection=$collection_name --file=/tmp/$collection_name.jq.json

}

clone_collections() {
    REST_ENDPOINT=$1  
	read_token=$2
    for collection in entries activity devicestatus food profile treatments;
    do echo cloning  "<$collection>"; 
    clone_collection $REST_ENDPOINT $collection $read_token
    done
}

# Try 5 times to get the user input.
for i in {1..5}
do
    read -rep "If you want to copy your old nightscout site, please state the name here"$'\n'"(for example: https://site.herokuapp.com). To skip presses enter."$'\n'"You will be able to run this in the future if needed. "$'\n'"site name: " rest_endpoint
    if [[ -z "$rest_endpoint" ]]
    then
        echo "No site selcted, exiting."
        exit
    fi
    #check if url ends with /, and if yes remove it.
    if [[ "$rest_endpoint" =~ '/'$ ]]; then 
        echo "yes"
        rest_endpoint=${rest_endpoint::-1}
    fi

    read -rep "If you have a read token, enter it now. For example: read-c9b67850b67acf82"$'\n'"If you don't know use a token press enter."$'\n'"read_token:" read_token
    if [[ ! -z "$read_token" ]]
    then
        echo "Token exists"
        read_token="&token="$read_token
    fi

    # do a sanity check before actually starting to copy.
    wget $rest_endpoint/api/v1/entries'.json?find[date][$gte]=1662845659&count=1'$read_token -O /tmp/entries.json
    ret_code=$?
    if [ ! $ret_code = 0 ]; then
        echo "Accesseing site " $rest_endpoint "failed, please try again, enter to skip."
        continue;
     fi

     echo Startint to copy $rest_endpoint
     clone_collections $rest_endpoint $read_token
     exit 0
   
done
