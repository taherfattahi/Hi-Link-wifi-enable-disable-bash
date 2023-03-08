#!/bin/bash

username='root'
password=''
getSysAuth=$(curl -D headers.txt -X POST -F 'luci_username='${username}'' -F 'luci_password='${password}'' http://192.168.1.1/cgi-bin/luci)

substrSysAuth="sysauth="
sysauth=""
while read line; do
    if [[ $line == *"$substrSysAuth"* ]];
    then
        # echo $line
        sysAuthIndex=${line/sysauth*/}
        
        indexStart=${#sysAuthIndex}
        indexStart=$((indexStart + 9))
        indexEnd=${#sysAuthIndex}
        indexEnd=$((indexEnd + 40))

        sysauth=$(echo $line| cut -c ${indexStart}-${indexEnd})
    else
        true
    fi
done < headers.txt


getSessionIdToken=$(curl --cookie "sysauth=${sysauth}" http://192.168.1.1/cgi-bin/luci >> headers.txt)

substrSessionIdToken="L = new LuCI("
sessionId=""
tokenId=""
while read line; do
    if [[ $line == *"$substrSessionIdToken"* ]];
    then
        sessionIndex=${line/sessionid*/}
        tokenIndex=${line/token*/}
        
        indexStart=${#sessionIndex}
        indexStart=$((indexStart + 13))
        indexEnd=${#sessionIndex}
        indexEnd=$((indexEnd + 44))

        sessionId=$(echo $line| cut -c ${indexStart}-${indexEnd})

        indexStart=${#tokenIndex}
        indexStart=$((indexStart + 9))
        indexEnd=${#tokenIndex}
        indexEnd=$((indexEnd + 40))

        tokenId=$(echo $line| cut -c ${indexStart}-${indexEnd})
    else
        true
    fi
done < headers.txt

echo $sysauth
echo $sessionId
echo $tokenId

#"[{'jsonrpc': '2.0','id':'" + 1 + "', 'method': 'call', 'params': ['" + sessionId + "', 'uci', 'delete', {'config': 'wireless', 'section': 'default_radio0', 'options': ['disabled']}]},{'jsonrpc': '2.0','id':'" + 2 + "', 'method': 'call', 'params': ['" + sessionId + "', 'uci', 'delete', {'config': 'wireless', 'section': 'radio0', 'options': ['disabled']}]}]";

generate_post_data()
{
  cat <<EOF
  [{"jsonrpc": "2.0","id": 1,"method": "call","params": ["${sessionId}","uci","delete",{"config": "wireless","section": "default_radio0","options": ["disabled"]}]},{"jsonrpc": "2.0","id": 2,"method": "call","params": ["${sessionId}","uci","delete",{"config": "wireless","section": "radio0","options": ["disabled"]}]}]
EOF
}

disableNetwork=$(curl -X POST http://192.168.1.1/ubus/ -H 'Content-Type: application/json' -d "$(generate_post_data)")

disableApplyNetwork=$(curl -v  --cookie "sysauth=${sysauth}" -X POST -F 'sid='${sessionId}'' -F 'token='${tokenId}'' http://192.168.1.1/cgi-bin/luci/admin/uci/apply_unchecked)

file="headers.txt"
if [ -f "$file" ] ; then
    rm "$file"
fi