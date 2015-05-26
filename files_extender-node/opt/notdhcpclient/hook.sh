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
MESH_VLAN="1"
MESH_IFACE="eth0.${MESH_VLAN}"

# The VLAN and interface that carries the open network
# a.k.a. the network with ssid set to peoplesopen.net
OPEN_VLAN="2"
OPEN_IFACE="eth0.${OPEN_VLAN}"

# Takes an IP string as an argument
# returns success (0) if the IP is bad
# returns failure (1) if the IP is good
badIP() {
  local ret

  ret=$(echo $1 | grep [^\.0-9] | wc -l)
  if [ "$ret" -gt "0" ]; then
    return 0
  fi

  if [ "${#1}" -gt "15" || "${#1}" -lt "7" ]; then
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

  if [ "${#1}" -gt "2" || "${#1}" -lt "1" ]; then
    return 0
  fi

  return 1
}

if badIP $IP; then
  echo "notdhcpclient hook script received a bad IP: $IP" >&2
  exit 1
fi

if badNetmask $NETMASK; then
  echo "notdhcpclient hook script received a bad netmask: $NETMASK" >&2
  exit 1
fi

case $STATE in
    "up")
        # Create the VLAN interfaces
        ip link add link $IFACE name $MESH_IFACE type vlan id $MESH_VLAN
        ip link add link $IFACE name $OPEN_IFACE type vlan id $OPEN_VLAN
        
        # TODO Bring up the wifi interfaces

        # TODO Create the two bridges

        # TODO Add interfaces to bridges

        # TODO Assign the IP address to both bridges
        ip addr add ${IP}/${NETMASK} 

        ;;


    "down")
        # TODO Remove interfaces from bridges

        # TODO Remove bridges

        # TODO Bring down wifi interfaces

        # Remove the VLAN interfaces
        ip link del dev $MESH_IFACE
        ip link del dev $OPEN_IFACE

        ;;

    *)
        echo "Error: Unexpected state received" >&2
        
esac
