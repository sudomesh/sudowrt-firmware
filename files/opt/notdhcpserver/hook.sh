#!/bin/sh

depends=""

for file in /etc/sudomesh/*; do
  depends="$depends $file"
done

STATE=$1 # "up" when an ACK was received or "down" on physical disconnect
IFACE=$2 # The interface that received the ACK or physical disconnect
IP=$3 # The IP that was handed out to the $IFACE
NETMASK=$4 # The netmask that was handed out to $IFACE
PASSWORD=$5 # The password that was handed out to $IFACE (on STATE="up" only)

OPEN_IFACE="br-open" # The open bridge interface
OPEN_VLAN="10" # The VLAN ID of the br-open network

PRIV_IFACE="br-priv" # The private bridge interface
PRIV_VLAN="11" # The VLAN ID of the br-priv network

VLAN=${IFACE##*.} # The VLAN ID of the receiving interface 

PORT=$(swconfig dev switch0 vlan $VLAN get ports)
PORT=$(echo $PORT | awk -e "{ sub(/ *0t? */, \"\", \$RESULT); print \$RESULT }")
PORT=$(echo $PORT | awk -e "{ sub(/t/, \"\", \$RESULT); print \$RESULT }")

log "PORT=$PORT"
log "VLAN=$VLAN"

case $STATE in
    "up")
        
        # change the port to be tagged (same VLAN)
        swconfig dev switch0 vlan $VLAN set ports "0t ${PORT}t"

        # add the port to the br-open VLAN (VLAN 10)
        OLD_PORTS=$(swconfig dev switch0 vlan $OPEN_VLAN get ports)
        swconfig dev switch0 vlan $OPEN_VLAN set ports "$OLD_PORTS ${PORT}t"

        # add the port to the br-priv VLAN (VLAN 11)
        OLD_PORTS=$(swconfig dev switch0 vlan $PRIV_VLAN get ports)
        swconfig dev switch0 vlan $PRIV_VLAN set ports "$OLD_PORTS ${PORT}t"

        # apply the changes to the switch
        swconfig dev switch0 set apply

        # add interface to babeld
        babeld -a $IFACE 
        ;;


    "down")

        # remove the port from the br-priv VLAN (VLAN 11)
        OLD_PORTS=$(swconfig dev switch0 vlan $PRIV_VLAN get ports)
        NEW_PORTS=$(echo $OLD_PORTS | awk -e "{ sub(/ *${PORT}t? */, \" \", \$RESULT); print \$RESULT }")
        swconfig dev switch0 vlan $PRIV_VLAN set ports "$NEW_PORTS"

        # remove the port from the br-open VLAN (VLAN 10)             
        OLD_PORTS=$(swconfig dev switch0 vlan $OPEN_VLAN get ports)
        NEW_PORTS=$(echo $OLD_PORTS | awk -e "{ sub(/ *${PORT}t? */, \" \", \$RESULT); print \$RESULT }")
        swconfig dev switch0 vlan $OPEN_VLAN set ports "$NEW_PORTS"

        # change the port to be untagged (same VLAN)
        swconfig dev switch0 vlan $VLAN set ports "0t ${PORT}"

        # apply the changes to the switch
        swconfig dev switch0 set apply

        # remove interface from babeld
        babeld -x $IFACE 
        ;;

    *)
        echo "Error: Unexpected state received" >&2
        
esac




