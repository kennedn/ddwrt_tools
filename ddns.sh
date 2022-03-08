#!/bin/sh

##############################################################
#							     #
# This script is designed to do a local compare between      #
# the routers nvram WAN IP and the last WAN IP we updated    #
# afraid dns with. If it notices a change it updates afraid. #
#							     #
##############################################################

WANIP="$(cat /tmp/ddns_oldWAN 2> /dev/null)"
TMPIP="$(nvram get wan_ipaddr)"

. $(dirname $0)/common.sh
. $(dirname $0)/.credentials
lastrun

# Lets not update afraid with a dead IP
if [ -z "${TMPIP}" ] || [ "${TMPIP}" = "0.0.0.0" ]; then
  log "No WAN ip exist, not updating"
  exit 1
fi
# If we detect a change to our current ip
if [ "${TMPIP}" != "${WANIP}" ]; then
  # Login to afraid and validate cookie, 6 months without login causes account to enter "dormant" state
  curl --interface ppp0 -so /dev/null "https://freedns.afraid.org/zc.php?step=2" -d "action=auth&submit=Login&username=${AFRAID_USER}&password=${AFRAID_PASSWORD}" -c - | grep -q dns_cookie && login_success=1 || login_success=
  
  # Try sending an update to afraid DDNS
  cOut=$(curl --interface ppp0 -w "%{http_code}" -sk "https://sync.afraid.org/u/${AFRAID_TOKEN}/") 
  # Split out success/failure message and http status code
  message="$(echo "$cOut" | head -n 1 | sed 's/000//g')"
  code="$(echo "$cOut" | tail -n 1)"
  log "${message}"

  # Check if the return code was a 200, if it wasn't send an alert out via the flask API
  if [ "${code}" != "200" ] || [ -z "${login_success}" ]; then
  	# Sometimes the router struggles with ip resolution, so just try sending until we get a 0 return code
  	rt=1; i=0
  	while [ "${rt}" != 0 ]; do
  		if [ "${i}" -ge 10 ]; then
  			break
  		fi

      if [ "${code}" != "200" ]; then
        curl -so /dev/null -H "Content-Type: application/json" -d '{"message": "'"$(caller) has encountered return code ${code}"'", "title": "router.int", "priority": "1", "api_token": "'"${NOTIFY_TOKEN}"'"}' -X PUT "http://192.168.1.107/api/v1.0/alert"
        rt=$?
        log "$(caller) has encountered return code ${code}"
      fi
      if [ -z "${login_success}" ]; then
        curl -so /dev/null -H "Content-Type: application/json" -d '{"message": "'"Login failed for $(caller)"'", "title": "router.int", "priority": "1", "api_token": "'"${NOTIFY_TOKEN}"'"}' -X PUT "http://192.168.1.107/api/v1.0/alert"
        log "Login failed for $(caller)"
      fi
          
  		i=$((i+1))
  	done
  fi
  echo "${TMPIP}" > /tmp/ddns_oldWAN
  cp /tmp/ddns_oldWAN "$(dirname "$0")/wan_ip"
fi
