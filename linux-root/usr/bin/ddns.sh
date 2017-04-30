#!/bin/sh

#################################################################
# This script has been tested under OpenWrt Chaos Calmer 15.05. #
#################################################################

validateIp() {
        oldIFS=$IFS
        IFS=.
        set -- $1
        IFS=${oldIFS}

        # Ensure there are 4 parts.
        [[ "$#" -ne "4" ]] && exit 1

        for oct in $1 $2 $3 $4; do
                # Ensure \'${oct}\' is within [0, 255].
                [[ "${oct}" -lt "0" || "${oct}" -gt "255" ]] && exit 1
        done
}

source ~/.ddns

echo Retrieving current IP...
currentIp=$(curl -s ${IP_SERVICE})
if [ "$?" -ne "0" ]; then
        echo Something wrong when retrieving dynamic IP. Exiting now and will try again later.
        exit 1
fi

echo Current IP is ${currentIp}.
validateIp ${currentIp}

lastIp=$(curl -X POST -k https://dnsapi.cn/Record.Info -d "login_token=${LOGIN_ID},${LOGIN_TOKEN}&format=json&domain_id=${DOMAIN_ID}&record_id=${RECORD}" | grep -o "${currentIp}")
echo Last IP record is ${lastIp}.

[ "${currentIp}" == "${lastIp}" ] && echo IP unchanged. && exit 0

echo Updating DDNS record...
curl -X POST -k https://dnsapi.cn/Record.Ddns -d "login_token=${LOGIN_ID},${LOGIN_TOKEN}&format=json&domain_id=${DOMAIN_ID}&record_id=${RECORD}&record_line=默认&sub_domain=${SUB_DOMAIN}"
