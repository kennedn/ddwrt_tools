#!/bin/sh

##############################################################
#	                                          						     #
# This script is designed to do ddns updates by performing   #
# a local compare between the routers nvram WAN IP and the   #
# last WAN IP we updated ddns with.                          #
# If it notices a change it updates the ddns.                #
# The script is designed to be placed as a 'Custom Script'   #
# under Administration -> Commands on a dd-wrt router.       #
#	                                          						     #
##############################################################

#AFRAID_TOKEN=
#AFRAID_USER=
#AFRAID_PASSWORD=
NOTIFY_TOKEN=
NAMECHEAP_HOSTNAME=
NAMECHEAP_PASSWORD=
WANIP="$(cat /tmp/ddns_oldWAN 2> /dev/null)"
TMPIP="$(nvram get wan_ipaddr)"
INTERFACE=ppp0
#INTERFACE=usb0

# sh safe .sh strip from calling scriptname
caller() {
  echo "ddns"
}

lastrun() {
  touch /tmp/$(caller).lastrun
}

# Timestamp logs, output to file and stdout
log() {
    echo "$(date +'%d/%m/%Y %H:%M:%S') $@" | tee -a /var/log/$(caller)
}

lastrun

# Lets not update afraid with a dead IP
if [ -z "${TMPIP}" ] || [ "${TMPIP}" = "0.0.0.0" ]; then
  log "No WAN ip exist, not updating"
  exit 1
fi
# If we dont detect a change to our current ip
[ "${TMPIP}" == "${WANIP}" ] && exit 0

# Login to afraid and validate cookie, 6 months without login causes account to enter "dormant" state
#curl --interface ${INTERFACE} -so /dev/null "https://freedns.afraid.org/zc.php?step=2" -d "action=auth&submit=Login&username=${AFRAID_USER}&password=${AFRAID_PASSWORD}" -c - | grep -q dns_cookie && login_success=1 || login_success=
login_success=1

# Try sending an update to afraid DDNS
#cOut=$(curl --interface ${INTERFACE} -w "%{http_code}" -sk "https://sync.afraid.org/u/${AFRAID_TOKEN}/")

# Update root domain (@) ddns entry, setting host='' defaults to root domain
cOut=$(curl --interface ${INTERFACE} -w "\n%{http_code}" -sk "https://dynamicdns.park-your-domain.com/update?host=&domain=${NAMECHEAP_HOSTNAME}&password=${NAMECHEAP_PASSWORD}")
# Split out success/failure message and http status code
#message="$(echo "$cOut" | sed '$d' | sed 's/000//g')"
code="$(echo "$cOut" | tail -n 1)"
# Update wildcard domain (*) ddns entry
cOut2=$(curl --interface ${INTERFACE} -w "\n%{http_code}" -sk "https://dynamicdns.park-your-domain.com/update?host=*&domain=${NAMECHEAP_HOSTNAME}&password=${NAMECHEAP_PASSWORD}")
# Split out success/failure message and http status code
#message="$(echo "$cOut" | sed '$d' | sed 's/000//g')"
code2="$(echo "$cOut" | tail -n 1)"
#[ -n "${message}" ] && log "${message}"

if [ "${code}" == "200" ] && [ "${code2}" == "200" ] ; then
  echo "${TMPIP}" > /tmp/ddns_oldWAN
  cp /tmp/ddns_oldWAN "$(dirname "$0")/wan_ip"
fi

# Check if the return code was a 200, if it wasn't send an alert out via the flask API
[ "${code}" == "200" ] && [ "${code2}" == "200" ] && [ -n "${login_success}" ] && log "Updated DDNS to ${TMPIP}" && exit 0

# Sometimes the router struggles with ip resolution, so just try sending until we get a 0 return code
i=0
while true; do
  [ "${code}" == "200" ] && break
  [ "${i}" -ge 10 ] && log "Max retry reached for alert \"$(caller) has encountered return code ${code}\"" && break
  curl -so /dev/null -H "Content-Type: application/json" -d '{"message": "'"$(caller) has encountered return code ${code}"'", "title": "router.int", "priority": "1", "api_token": "'"${NOTIFY_TOKEN}"'"}' -X PUT "https://api.kennedn.com/v1/alert" || { i=$((i+1)); continue; }
  log "$(caller) has encountered return code ${code}"
  break
done

i=0
while true; do
  [ -n "${login_success}" ] && break
  [ "${i}" -ge 10 ] && log "Max retry reached for alert \"Login failed for $(caller)\"" && break
  curl -so /dev/null -H "Content-Type: application/json" -d '{"message": "'"Login failed for $(caller)"'", "title": "router.int", "priority": "1", "api_token": "'"${NOTIFY_TOKEN}"'"}' -X PUT "https://api.kennedn.com/v1/alert" || { i=$((i+1)); continue; }
  log "Login failed for $(caller)"
  break
done
