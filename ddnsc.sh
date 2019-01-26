#!/bin/bash

scriptdir=$(dirname $0)

. $scriptdir/config

curlParams="$curlParams --user-agent ddnsc/0.1"


log() {
   logger -t ddnsc -p daemon.notice "$1: $2"
   echo $(date '+%Y-%m-%d %H:%M:%S') $1: $2
}


update=0

sleep $[RANDOM%$jitter]

if [ -f $scriptdir/lastip ]; then
  lastIP=$(< $scriptdir/lastip)
  lastIPepoch=$(date +%s -r $scriptdir/lastip)
else
  lastIP="unknown"
  lastIPepoch=0
fi

forceEpoch=$(date +%s --date="$force ago")

actIP=$(curl $curlParams $urlIP)
rc=$?

if [ $rc -ne 0 ]; then
  log "error" "curl $rc"
  exit
fi

actIP=$(echo "$actIP" | grep -oE '((1?[0-9][0-9]?|2[0-4][0-9]|25[0-5])\.){3}(1?[0-9][0-9]?|2[0-4][0-9]|25[0-5])' | head -1)

if [ "$lastIP" != "$actIP" ]; then
  log "info" "ip address change detected ($lastIP --> $actIP)"
  update=1
fi

if [ $lastIPepoch -lt $forceEpoch ]; then
  log "info" "last update $force ago, forcing update"
  update=1
fi

if [ $update -eq 1 ]; then
  response=$(curl $curlParams $urlDdns)
  rc=$?

  if [ $rc -ne 0 ]; then
    log "error" "curl $rc"
    exit
  fi
  
  response=$(echo "$response" | sed 's/<[^>]*>/ /g;s/^\s*//g;s/\s*$//g' | tr -s ' ')

  if [[ "$response" =~ (Success|good|nochg) ]]; then
    log "success" "$response"
    echo -n $actIP > $scriptdir/lastip
  else
    log "error" "$response"
  fi

fi


