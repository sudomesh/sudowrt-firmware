# Sudo Mesh Operator Manual

This manual should help operators to:

 * get started with sudo mesh (network) design
 * test newly built node firmware
 * create and maintain home, extender and exit nodes
 * train new operators

# Getting Started

To get started with meshing nodes, you can do the following:

prequisites - 
1. access to internet connection (for makenode, mesh testing)
1. ubuntu computer (other operating system probably also works)
1. two home nodes (mynet n600 / n750)

steps -
1. configure both nodes using https://peoplesopen.net/walkthrough
1. ssh into both nodes from computer using hardwired port 3 connection
1. identify mesh ip addresses for both 
1. verify that private/open and adhoc wifi ssids are present 
1. verify that each of the local nodes can ping each other
1. turn off one node, and verify that other node can no longer ping 
1. turn both nodes on, connect one to the internet using hardwired internet port. Then, on the node that is not hardwired to internet, try to ping a public ip address like 8.8.8.8 .

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


## digging a tunnel to exit node to check that you can 

To check whether tunnel to exit node can be made, you can start a tunneldigger client on your laptop. No need for router. (tested on ubuntu 16.04).

1. get tunneldigger ```git clone git@github.com:wlanslovenija/tunneldigger.git``` . Note that the sudomesh tunneldigger fork does not compile on ubuntu as far as I know.
2. install packages if needed (see http://tunneldigger.readthedocs.io/en/latest/server.html#prerequisites)
3. compile tunneldigger client ```tunneldigger/client$cmake . && make 
4. prior to digging a tunnel, check interfaces using ```ip addr```, udp ports using ```netstat -u``` and syslog using ```cat /var/log/syslog | grep td-client```
5. dig a tunnel using ```sudo ./tunneldigger -b exit.sudomesh.org:8942 -u 07105c7f-681f-4476-b5aa-5146c6e579de  -i l2tp0```
5. also, check ```ip addr``` and verify that an interface ```l2tp0``` now exists. 
6. also, open udp ports ```netstat -u``` and verify that a something like:
```
Active Internet connections (w/o servers)
Proto Recv-Q Send-Q Local Address           Foreign Address         State      
udp        0      0 xxxx:42862         unassigned.psychz.:8942 ESTABLISHED
```
7. verify syslog entries using ```cat /var/log/syslog | grep td-client``` - expecting something like:

```
Dec 17 13:24:06 xx td-client: Performing broker selection...
Dec 17 13:24:08 xx td-client: Broker usage of exit.sudomesh.org:8942: 1471
Dec 17 13:24:08 xx td-client: Selected exit.sudomesh.org:8942 as the best broker.
Dec 17 13:24:12 xx td-client: Tunnel successfully established.
Dec 17 13:24:21 xx td-client: Setting MTU to 1446
```


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
 * ethernet port 3 - eth0.11 (private)
 * ethernet port 4 - eth0.10 (open)
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
