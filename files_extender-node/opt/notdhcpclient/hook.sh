#!/bin/sh

# TODO check password, ssl_cert_path and ssl_key_path for malicious inputs

STATE=$1 # the string "up" or "down"
IFACE=$2 # the interface that received an IP
IP=$3 # the received IP
NETMASK=$4 # the received netmask
PASSWORD=$5 # the received password
SSL_CERT_PATH=$6 # path to the received SSL cert
SSL_KEY_PATH=$7 # path to the received SSL key

# The VLAN and interface that carries the mesh network
# a.k.a. the adhoc or node2node network
MESH_VLAN="11"
MESH_ETH="eth0.${MESH_VLAN}"

# The VLAN and interface that carries the open network
# a.k.a. the network with ssid set to peoplesopen.net
OPEN_VLAN="10"
OPEN_ETH="eth0.${OPEN_VLAN}"

# The wireless interfaces
MESH_WLAN="adhoc0"
OPEN_WLAN="open0"

# The two bridges
MESH_BRIDGE="br-adhoc"
OPEN_BRIDGE="br-open"

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

case $STATE in
    "up")

        # Check if the IP looks valid
        if badIP $IP; then
          echo "notdhcpclient hook script received a bad IP: $IP" >&2
          exit 1
        fi
        
        # Check if the netmask looks valid
        if badNetmask $NETMASK; then
          echo "notdhcpclient hook script received a bad netmask: $NETMASK" >&2
          exit 1
        fi

        echo "Creating VLAN interfaces"
        ip link add link $IFACE name $MESH_ETH type vlan id $MESH_VLAN
        ip link add link $IFACE name $OPEN_ETH type vlan id $OPEN_VLAN

        echo "Setting VLAN interface link states to up"
        ip link set dev $MESH_ETH up
        ip link set dev $OPEN_ETH up

        echo "Enabling wireless"
        # This does not persist between reboots
        uci set wireless.@wifi-device[0].disabled=0
        wifi
        sleep 5

        # Use policy routing to forward:
        #   everything from eth0.1 to adhoc0
        #   everything from adhoc0 to eth0.1
        # We're not using bridging here because it doesn't work for adhoc networks
        echo "Initializing policy routing (layer 3 bridge)"
        ip route add default dev $MESH_ETH table mesh_wlan
        ip rule add iif $MESH_WLAN lookup mesh_wlan
        ip route add default dev $MESH_WLAN table mesh_eth
        ip rule add iif $MESH_ETH lookup mesh_eth

        # Create the open (peoplesopen.net) bridge between ethernet and wifi
        echo "Creating bridge between $OPEN_ETH and $OPEN_WLAN"
        brctl addbr $OPEN_BRIDGE
        brctl addif $OPEN_BRIDGE $OPEN_ETH
        brctl addif $OPEN_BRIDGE $OPEN_WLAN

        echo "Assigning IP ${IP}/${NETMASK} to $OPEN_BRIDGE"
        ip addr add ${IP}/${NETMASK} dev $OPEN_BRIDGE

#        echo "Setting route for $OPEN_BRIDGE"
#        ip route add ${IP}/${NETMASK} dev $OPEN_BRIDGE proto kernel scope link

        echo "Setting $OPEN_BRIDGE state to up"
        ip link set dev $OPEN_BRIDGE up
        ;;


    "down")
        echo "Remove policy routing rules"
        ip route del default dev $MESH_ETH table mesh_wlan
        ip rule del iif $MESH_WLAN lookup mesh_wlan
        ip route del default dev $MESH_WLAN table mesh_eth
        ip rule del iif $MESH_ETH lookup mesh_eth

        echo "Taking down bridge"
        ip link set dev $OPEN_BRIDGE down

        echo "Removing bridge"
        brctl delif $OPEN_BRIDGE $OPEN_ETH
        brctl delif $OPEN_BRIDGE $OPEN_WLAN
        brctl delbr $OPEN_BRIDGE

        echo "Bringing down wifi"
        uci set wireless.@wifi-device[0].disabled=1
        wifi down

        echo "Removing VLAN interfaces"
        ip link del dev $MESH_ETH
        ip link del dev $OPEN_ETH
        ;;

    *)
        echo "Error: Unexpected state received" >&2
        
esac
