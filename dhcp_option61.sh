#!/bin/sh	    

###########################################################
#							  #
# Check if we have DHCP lease from Sky (E.g a WAN IP).    #
# If we don't, login to sky using DHCP option 61 (0x3d),  #
# Using the credentials we sniffed from Now TV router     #
#							  #
###########################################################


# Load Common Functions
. $(dirname $0)/common.sh
lastrun

TMPIP="$(nvram get wan_ipaddr)"

if [ -z "${TMPIP}" ] || [ "${TMPIP}" = "0.0.0.0" ] || [ "$1" == "-f" ]; then
  log "Router has no DHCP lease, renewing"

  # Option 0x3d = 61 dhcp - hex encoded username and password 
  sExec killall udhcpc
  # Sky DSL
  if sExec udhcpc -i eth0 -p /var/run/udhcpc.pid -s /tmp/udhcpc -O routes -O msstaticroutes -O staticroutes -H router -x 0x3d:39633331633335313564663040736b7964736c7c375650683434545a; then
  # Now TV 
#  if sExec udhcpc -i eth0 -p /var/run/udhcpc.pid -s /tmp/udhcpc -O routes -O msstaticroutes -O staticroutes -H router -x 0x3d:336338393934666135346130406e6f7774767c434c585072667334; then
    log "DHCP lease renewed with Option 61"
  else
    log "Failed to renew DHCP lease"
    rt=1; i=0
    while [ "${rt}" != 0 ]; do
            if [ "${i}" -ge 10 ]; then
                    break
            fi
            curl -H "Content-Type: application/json" -d '{"message": "'"$0 has failed to renew DHCP"'", "title": "router.int", "priority": "1", "api_token": "aopv3qp5jzjqpy8i5vr83kzie4cj4k"}' -X PUT "http://192.168.1.107/api/v1.0/alert"
            rt=$?
            i=$((i+1))
    done
  fi

fi

