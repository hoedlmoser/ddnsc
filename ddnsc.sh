#!/bin/bash

scriptdir=$(dirname $0)

. $scriptdir/config

curlParams+=" --user-agent ddnsc/0.1"


log() {
   logger -t ddnsc -p daemon.notice "$1: $2"
   echo $(date '+%Y-%m-%d %H:%M:%S') $1: $2
}


sleep $[RANDOM%$jitter]

for ipType in ${ipTypes[*]}; do

  update=0

  if [ -f $scriptdir/lastip$ipType ]; then
    lastIP=$(< $scriptdir/lastip$ipType)
    lastIPepoch=$(date +%s -r $scriptdir/lastip$ipType)
  else
    lastIP="unknown"
    lastIPepoch=0
  fi

  forceEpoch=$(date +%s --date="$force ago")

  qipUrl="$qipScheme://${qipHostPrefix[$ipType]:+${qipHostPrefix[$ipType]}.}$qipHost/$qipPath"
  actIP=$(curl $curlParams $curlParamIp[$ipType] $qipUrl)
  rc=$?

  if [ $rc -ne 0 ]; then
    log "error" "curl $rc"
    exit
  fi

  actIP=$(echo "$actIP" | grep -oP '((\d{1,3}\.){3}\d{1,3}|([\da-fA-F]{1,4}:){1,7}((:[\da-fA-F]{1,4}){1,6}|[\da-fA-F]{1,4}|:))' | head -1)

  if [ "$lastIP" != "$actIP" ]; then
    log "info" "ip address change detected ($lastIP --> $actIP)"
    update=1
  fi

  if [ $lastIPepoch -lt $forceEpoch ]; then
    log "info" "last update > $force ago, forcing update"
    update=1
  fi

  if [ $update -eq 1 ]; then
    ddnsUrl="$ddnsScheme://${ddnsHostPrefix[$ipType]:+${ddnsHostPrefix[$ipType]}.}$ddnsHost/$ddnsPath${ddnsQuery:+?$ddnsQuery}"
    response=$(curl $curlParams $curlParamIp[$ipType] $ddnsUrl)
    rc=$?

    if [ $rc -ne 0 ]; then
      log "error" "curl $rc"
      exit
    fi
  
    response=$(echo "$response" | sed 's/<[^>]*>/ /g;s/^\s*//g;s/\s*$//g' | tr -s ' ')

    if [[ "$response" =~ (good|nochg) ]]; then
      log "success" "$response"
      echo -n $actIP > $scriptdir/lastip$ipType
    else
      log "error" "$response"
    fi

  fi

done

