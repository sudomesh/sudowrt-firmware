# Sudo Mesh operator manual

This manual should help operators to:

 * get started with sudo mesh (network) design
 * test newly built node firmware
 * create and maintain home, extender and exit nodes
 * train new operators


# Troubleshooting

## no internet connection

1. Configure your ethernet port to a local address (e.g., 172.30.0.9) after removing existing ip addresses (see [#tips-and-tricks])
1. Login to home node using ethernet port 3 of home node.
1. identify mesh ip4 address using ```cat /etc/config/network```. Note that mesh ip addresses start with 100.65 .
1. inspect babeld (meshing protocol) traffic using ```babeld -i```
1. inspect routing table using ```ip route show table public```
1. ping a name server on the internet using ```ip -I mesh5 8.8.8.8```

## not flashing

1. reset router, try again


# Tips and Tricks

```bash
# show devices
ip addr

# show specific device
ip addr dev enp0s25

# remove ip address for device enp0s25
ip addr del 172.30.0.9/24 dev enp0s25

# change ip address 
ip addr change 172.30.0.9/24 dev enp0s25

# show public routing table
ip route show table public

# show private routing table
ip route

# show babeld status (only for sudomesh babeld?)
babeld -i

# ping public ip through mesh5 interface
ping -I mesh5 
```

## Mesh Network Components

### Home Node
Home nodes can talk to, or mesh with, each other directly (ad-hoc) or through a vpn-tunnel to exit server via internet connection. Home Nodes run an altered openwrt firmware (see https://github.com/sudomesh/sudowrt-firmware) and are configured using makenode (see https://github.com/sudomesh/makenode).

Home nodes have:

 * two radios (radio0 2.4 GHz, radio1 5 GHz) see ```/etc/config/wireless```
 * three networks (open, private, adhoc/mesh) see ```/etc/config/network```
 * five physical ports (1-4 + yellow internet)
 * ethernet port 1 - eth0.1 
 * ethernet port 2 - eth0.2
 * ethernet port 3 - eth0.10
 * ethernet port 4 - eth0.11
 * ethernet yellow-internet - eth0.5

 Makenode configures these networks after flashing the firmware. (see https://peoplesopen.net/walkthrough)

Home Nodes run:

  * babeld to mesh 
  * tunneldigger to create vpn tunnel to exit server
  * dnsmasq to handout ip addresses (dns) to clients 

### Exit Node

Exit Nodes (see https://github.com/sudomesh/exitnode) run a VPN server for home nodes to tunnel into a mesh network. Also, the exit node tunnels traffic from the mesh to the internet.

An Exit Node runs:
  
  * babeld to mesh
  * ? to host vpn tunnel
