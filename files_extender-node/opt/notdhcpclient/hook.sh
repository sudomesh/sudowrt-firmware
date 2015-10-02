#!/bin/sh

. /usr/share/libubox/jshn.sh

# TODO check password, ssl_cert_path and ssl_key_path for malicious inputs

LOG_TAG="notdhcpclient_hook"

STATE=$1 # the string "up" or "down"
IFACE=$2 # the interface that received an IP
MESH_VLAN=$3 # the received VLAN ID (0 if no VLAN)
IP=$4 # the received IP
NETMASK=$5 # the received netmask
PASSWORD=$6 # the received password
SSL_CERT_PATH=$7 # path to the received SSL cert
SSL_KEY_PATH=$8 # path to the received SSL key

# The interface that carries the mesh network
# a.k.a. the adhoc or node2node network
MESH_ETH="eth0.${MESH_VLAN}"

# The VLAN and interface that carries the open network
# a.k.a. the network with ssid set to peoplesopen.net
OPEN_VLAN="10"
OPEN_ETH="eth0.${OPEN_VLAN}"

# The VLAN and interface that carries the private network
PRIV_VLAN="11"
PRIV_ETH="eth0.${PRIV_VLAN}"

# The wireless interfaces
MESH_WLAN="mesh0"
OPEN_WLAN="open0"
PRIV_WLAN="priv0"

# The bridge for the open (SSID: peoplesopen.net) network
OPEN_BRIDGE="br-open"

# The bridge for the private network
PRIV_BRIDGE="br-priv"

# Takes an IP string as an argument
# returns success (0) if the IP is bad
# returns failure (1) if the IP is good
badIP() {
  local ret

  ret=$(echo $1 | grep [^\.0-9] | wc -l)
  if [ "$ret" -gt "0" ]; then
    return 0
  fi

  if [ "${#1}" -gt "15" ]; then
    return 0
  fi

  if [ "${#1}" -lt "7" ]; then
    return 0
  fi

  return 1
}

# Takes a netmask string as an argument (of the form e.g: "24")
# returns success (0) if the netmask is bad
# returns failure (1) if the netmask is good
badNetmask() {
  local ret

  ret=$(echo $1 | grep [^0-9] | wc -l)
  if [ "$ret" -gt "0" ]; then
    return 0
  fi

  if [ "${#1}" -gt "2" ]; then
    return 0
  fi

  if [ "${#1}" -lt "1" ]; then
    return 0
  fi

  return 1
}

# Takes a message string as an argument and logs with our log tag
log() {

  echo $1; logger -t $LOG_TAG $1
 
}

# Waits for wifi to be ready
# TODO: accomodate multiple radios and have an eventual timeout
waitForWifi() {
  log "enters waitforwifi"
  local status
  local radios
  local wifi_up

  status=$(ubus call network.wireless status)
  json_load "$status"
  json_get_keys radios
  radios=$(echo "$radios" | tr -d ' ')

  while [ -z "$radios" ] ; do
    log "No radio loaded yet"
    status=$(ubus call network.wireless status)
    json_load "$status"
    json_get_keys radios
    radios=$(echo "$radios" | tr -d ' ')
    sleep 3
  done
  log "Radio is loaded: $radios"
  
  for radio in "$radios"; do
    log "Checking wireless radio $radio status"
    status=$(ubus call network.wireless status)
    json_load "$status"
    json_select $radio
    json_get_var wifi_up up
    log "$radio status $wifi_up"
  
    while [ "$wifi_up" != 1 ] ; do
      log "Checking wireless radio $radio status"
      status=$(ubus call network.wireless status)
      json_load "$status"
      json_select $radio
      json_get_var wifi_up up
      log "$radio status $wifi_up"

      sleep 3
    done
  done
}


case $STATE in
    "up")

        # Check if the IP looks valid
        if badIP $IP; then
          log "notdhcpclient hook script received a bad IP: $IP"
          exit 1
        fi
        
        # Check if the netmask looks valid
        if badNetmask $NETMASK; then
          log "notdhcpclient hook script received a bad netmask: $NETMASK"
          exit 1
        fi

        log "Creating VLAN interfaces"
        ip link add link $IFACE name $MESH_ETH type vlan id $MESH_VLAN
        ip link add link $IFACE name $OPEN_ETH type vlan id $OPEN_VLAN
        ip link add link $IFACE name $PRIV_ETH type vlan id $PRIV_VLAN

        log "Enabling wireless"
        # This does not persist between reboots
        uci set wireless.@wifi-device[0].disabled=0
        wifi
        waitForWifi

        log "Assigning IP ${IP}/32 to $MESH_WLAN"
        ip addr add ${IP}/32 dev $MESH_WLAN

        log "Assigning IP ${IP}/32 to $MESH_ETH"
        ip addr add ${IP}/32 dev $MESH_ETH

        log "Setting VLAN interface link states to up"
        ip link set dev $MESH_ETH up
        ip link set dev $OPEN_ETH up
        ip link set dev $PRIV_ETH up

        # Configure and start babeld    
        log "Starting babeld"
        uci set babeld.lan.ifname="$MESH_ETH"
        MESH_CHANNEL=$(uci get wireless.radio0.channel)
        uci set babeld.mesh.channel="$MESH_CHANNEL"

        /etc/init.d/babeld start 

        # Create the open (peoplesopen.net) bridge between ethernet and wifi
        log "Creating bridge between $OPEN_ETH and $OPEN_WLAN"
        brctl addbr $OPEN_BRIDGE
        brctl addif $OPEN_BRIDGE $OPEN_ETH

        # Looks like we might need a sleep in order to add open_wlan interface to bridge
        sleep 10
        brctl addif $OPEN_BRIDGE $OPEN_WLAN

        # Create the private bridge between ethernet and wifi               
        log "Creating bridge between $PRIV_ETH and $PRIV_WLAN"
        brctl addbr $PRIV_BRIDGE
        brctl addif $PRIV_BRIDGE $PRIV_ETH

        # Looks like we might need a sleep in order to add priv_wlan interface to bridge
        sleep 10
        brctl addif $PRIV_BRIDGE $PRIV_WLAN

        log "Assigning IP ${IP}/${NETMASK} to $OPEN_BRIDGE"
        ip addr add ${IP}/${NETMASK} dev $OPEN_BRIDGE

        log "Setting $OPEN_BRIDGE state to up"
        ip link set dev $OPEN_BRIDGE up

        log "Setting $PRIV_BRIDGE state to up"
        ip link set dev $PRIV_BRIDGE up
        ;;


    "down")

        log "Taking down bridge $OPEN_BRIDGE"
        ip link set dev $OPEN_BRIDGE down

        log "Taking down bridge $PRIV_BRIDGE"
        ip link set dev $PRIV_BRIDGE down

        log "Removing bridge $OPEN_BRIDGE"
        brctl delif $OPEN_BRIDGE $OPEN_ETH
        brctl delif $OPEN_BRIDGE $OPEN_WLAN
        brctl delbr $OPEN_BRIDGE

        log "Removing bridge $PRIV_BRIDGE"
        brctl delif $PRIV_BRIDGE $PRIV_ETH
        brctl delif $PRIV_BRIDGE $PRIV_WLAN
        brctl delbr $PRIV_BRIDGE

        log "Stopping babeld"
        /etc/init.d/babeld stop

        log "Bringing down wifi"
        uci set wireless.@wifi-device[0].disabled=1
        wifi down

        log "Removing VLAN interfaces"
        ip link del dev $MESH_ETH
        ip link del dev $OPEN_ETH
        ip link del dev $PRIV_ETH
        ;;

    *)
        log "Error: Unexpected state received"
        
esac
