#!/bin/bash

function check_valid_ip(){
    local  ip=$1
    local  stat=1
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}

PREP_LIST_API=`cat /etc/nginx/policy/.cron-env`

true > /etc/nginx/policy/prepnode_dynamicips_check.conf

IPLIST=`curl -d '{"jsonrpc": "2.0", "method": "icx_call", "id": 1234, "params": {"from": "hx0000000000000000000000000000000000000000", "to": "cx0000000000000000000000000000000000000000", "dataType": "call", "data": {"method": "getPRepTerm"}}}' ${PREP_LIST_API} |jq '.result.preps[].p2pEndpoint' | sed s/\"//g | sed s/:7100//g`

for IP in $IPLIST
do
   if check_valid_ip "$IP"; then
        echo "allow $IP;" >> /etc/nginx/policy/prepnode_dynamicips_check.conf
   fi
done


if [ "diff --brief /etc/nginx/conf.d/prepnode_allowips.conf /etc/nginx/policy/prepnode_dynamicips_check.conf" ]; then
    cp /etc/nginx/policy/prepnode_dynamicips_check.conf /etc/nginx/conf.d/prepnode_allowips.conf
fi
