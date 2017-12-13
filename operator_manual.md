# Sudo Mesh operator manual

This manual should help operators to:

 * get started with sudo mesh (network) design
 * test newly built node firmware
 * create and maintain home, extender and exit nodes
 * train new operators


# Troubleshooting

## no internet connection

1. Configure your ethernet port to a local address (e.g., 172.30.0.9) after removing existing ip addresses (see [#tips-and-tricks])
1. Login to home node using ethernet port 3 of home node and ```ssh root@172.30.0.1```. 

```bash
ssh root@172.30.0.1
root@172.30.0.1's password: 


BusyBox v1.23.2 (2017-11-21 21:45:39 UTC) built-in shell (ash)


  ._______.___    ._______.______  ._____  .___    .___ .______  ._____  
  :_ ____/|   |   : .____/:_ _   \ :_ ___\ |   |   : __|:      \ :_ ___\ 
  |   _/  |   |   | : _/\ |   |   ||   |___|   |   | : ||       ||   |___
  |   |   |   |/\ |   /  \| . |   ||   /  ||   |/\ |   ||   |   ||   /  |
  |_. |   |   /  \|_.: __/|. ____/ |. __  ||   /  \|   ||___|   ||. __  |
    :/    |______/   :/    :/       :/ |. ||______/|___|    |___| :/ |. |
    :                      :        :   :/                        :   :/ 
                                        :                             : 
 -------------------------------------------------------------------------
 sudo mesh v0.2 (fledgling)
                              based on OpenWRT 15.05 (Chaos Calmer)
 -------------------------------------------------------------------------
 “When your rage is choking you, it is best to say nothing.” 
                                            - Octavia E. Butler, Fledgling
 -------------------------------------------------------------------------
root@myfirstpony:~# 
```

1. identify mesh ip4 address using ```cat /etc/config/network```. Note that mesh ip addresses start with 100.65 .

```bash
root@myfirstpony:~# cat /etc/config/network | grep 100\.65 | uniq
option ipaddr '100.65.20.1'
```

1. inspect babeld (meshing protocol) traffic using ```babeld -i```

Example below show two meshing nodes (100.65.20.1 and 100.65.20.65)

```bash
root@myfirstpony:~# babeld -i
Listening on interfaces: l2tp0 mesh2 mesh5 eth0.1 eth0.2 

My id 02:90:a9:ff:fe:0b:4b:eb seqno 13230
Neighbour fe80::290:a9ff:fecd:cfd8 dev mesh5 reach ffff rxcost 256 txcost 65535 rtt 0.000 rttcost 0 chan 157.
Neighbour fe80::290:a9ff:fecd:cfd6 dev mesh2 reach fbf7 rxcost 264 txcost 257 rtt 0.000 rttcost 0 chan 6.
100.65.20.0/26 metric 128 (exported)
100.65.20.64/26 metric 393 (419) refmetric 128 id 02:90:a9:ff:fe:cd:cf:d6 seqno 26836 age 5 via mesh2 neigh fe80::290:a9ff:fecd:cfd6 nexthop 100.65.20.65 (installed)
100.65.20.64/26 metric 65535 (65535) refmetric 128 id 02:90:a9:ff:fe:cd:cf:d6 seqno 26836 age 2 via mesh5 neigh fe80::290:a9ff:fecd:cfd8 nexthop 100.65.20.65 (feasible)
```

1. inspect routing table using ```ip route show table public```

Example below show two meshing nodes (100.65.20.{1,65}) 
```bash
root@myfirstpony:~# ip route show table public
100.65.20.0/26 dev br-open  proto kernel  scope link  src 100.65.20.1 
100.65.20.64/26 via 100.65.20.65 dev mesh2  proto babel onlink 
```

1. ping a name server on the internet using ```ip -I mesh5 8.8.8.8```

If no route to internet is found, the icmp_seq messages will not appear.

```bash 
root@myfirstpony:~# ping -I mesh2 8.8.8.8
PING 8.8.8.8 (8.8.8.8): 56 data bytes
64 bytes from 8.8.8.8: icmp_seq=1 ttl=56 time=190 ms
64 bytes from 8.8.8.8: icmp_seq=2 ttl=56 time=189 ms
```

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
ping -I mesh5 8.8.8.8
```

## Mesh Network Components

### Home Node
Home nodes can talk to, or mesh with, each other directly (ad-hoc) or through a vpn-tunnel to exit server via internet connection. Home Nodes run an altered openwrt firmware (see https://github.com/sudomesh/sudowrt-firmware) and are configured using makenode (see https://github.com/sudomesh/makenode).

Home nodes have:

 * two radios (radio0 2.4 GHz, radio1 5 GHz) see ```/etc/config/wireless```
 * three networks (open, private, adhoc/mesh) see ```/etc/config/network```
 * five physical ports (1-4 + yellow internet)
 * ethernet port 1 - eth0.1 (mesh) 
 * ethernet port 2 - eth0.2 (mesh)
 * ethernet port 3 - eth0.10 (open)
 * ethernet port 4 - eth0.11 (private)
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
