A sudomesh firmware builder.

[![Build Status](https://travis-ci.org/sudomesh/sudowrt-firmware.svg?branch=master)](https://travis-ci.org/sudomesh/sudowrt-firmware)

# Pre-built Versions


Pre-built versions of the firmware can be found here:

 | name | architecture | version | link | commonly used |
|  --- | --- | --- | --- | --- |
| Home Node | ar71xx | 0.3.0 |  | [mynet n600](http://builds.sudomesh.org/builds/sudowrt/dispossessed/0.3.0/openwrt-ar71xx-generic-mynet-n600-squashfs-factory.bin) 
| Home Node | ar71xx | 0.2.3 | [![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.1205601.svg)](https://doi.org/10.5281/zenodo.1205601) | [mynet n600](https://zenodo.org/record/1205601/files/openwrt-ar71xx-generic-mynet-n600-squashfs-factory.bin) or [mynet n750](https://zenodo.org/record/1205601/files/openwrt-ar71xx-generic-mynet-n750-squashfs-factory.bin)
| Extender Node | ar71xx | 0.2.3 | [![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.1206171.svg)](https://doi.org/10.5281/zenodo.1206171) |

Now go to https://peoplesopen.net/walkthrough and follow the instructions to flash the firmware onto your router.

# Developing on this firmware

If you would like to make additions to the sudowrt-firmware, there a few ways in which to integrate your desired changes. First, figure out what change you are trying to make by testing it out on a live node. Most changes can be tested by sshing into a node and manually making the changes. The following 

## Adding an OpenWrt package
Maybe you'd like to expose a feature by installing an OpenWrt package. If you find yourself needing to run on your home node,
```
opkg update
opkg install <package-name>
```
You can build any package into the firmware by adding to the package name to the list located in `/openwrt_configs/packages`.

## Adding/modifiying system files 
Changes that need to be made in a node's system files can be added to in two places.

1. `files/` - this is where you should put configurations that are neccessary at very first boot or during the autoconfiguration process. Any changes to this directory may be overwritten by the second location.

2. `files/opt/mesh/templates/` - this directory is copied in after you recieve an IP on the mesh. The files here may also contain placeholders that can then be replaced with info relevant to People's Open Network (or any given mesh) during autoconfiguration. Files in this directory supersede `files/`

# System file descriptions

Most configurations relevant to People's Open Network are stored in [/etc/config/](https://github.com/sudomesh/sudowrt-firmware/tree/master/files/opt/mesh/templates/etc/config). These files can be alterted using OpenWrt's built-in UCI system, an example of how to use this can be seen in the [autoconf script](https://github.com/sudomesh/sudowrt-firmware/blob/master/files/opt/mesh/autoconf#L61), full documentation can be found [here](https://wiki.openwrt.org/doc/uci).

* [babeld](https://github.com/sudomesh/sudowrt-firmware/blob/master/files/opt/mesh/templates/etc/config/babeld) - configurations for babel routing protocol daemon, not sure how this differs from or interops with [/etc/babeld.conf](https://github.com/sudomesh/sudowrt-firmware/blob/master/files/opt/mesh/templates/etc/babeld.conf)
* [dhcp](https://github.com/sudomesh/sudowrt-firmware/blob/master/files/opt/mesh/templates/etc/config/dhcp) - configures dnsmasq and sets dhcp server IP addresses
* [firewall](https://github.com/sudomesh/sudowrt-firmware/blob/master/files/opt/mesh/templates/etc/config/firewall) - seems to do very little, most firewall settings are handled by meshrouting described in next section
* [network](https://github.com/sudomesh/sudowrt-firmware/blob/master/files/opt/mesh/templates/etc/config/network) - sets up physical ports and virutal interfaces for home node, takes the node's mesh IP and adds it to the necessary interfaces. Also, sets dns server IP addresses, usually the mesh IP of the exit node (e.g. 100.64.0.42 or 100.64.0.43).
* [notdhcpserver](https://github.com/sudomesh/sudowrt-firmware/blob/master/files/opt/mesh/templates/etc/config/notdhcpserver) - sets ports 1 and 2 on home node to only accept connections from devices with the pre-determined extender node IPs. Though, a device connected to these ports doesn't have to be an extender node, it can be any device with the correct IP, typically the node's mesh IP +1 or +2, usage well dcpoumented in the [services guide](https://github.com/sudomesh/babeld-lab/blob/master/services_guide.md#use-case---raspberry-pi-as-wired-mesh-node-via-home-node).
* [polipo](https://github.com/sudomesh/sudowrt-firmware/blob/master/files/opt/mesh/templates/etc/config/polipo) - configures cacheing, does not seem to be used by anything.
* [rpcd](https://github.com/sudomesh/sudowrt-firmware/blob/master/files/opt/mesh/templates/etc/config/rpcd) - sets rpcd login username and password, taken from passwd/shadow files mentioned below.
* [system](https://github.com/sudomesh/sudowrt-firmware/blob/master/files/etc/config/system) - sets the hostname of the node and configuration of indicator LEDs
* [tunneldigger](https://github.com/sudomesh/sudowrt-firmware/blob/master/files/opt/mesh/templates/etc/config/tunneldigger) - sets a list of potential tunnel brokers (i.e. exit nodes) as well as the interface to tunnel over and the upload/download bandwidth limits
* [uhttpd](https://github.com/sudomesh/sudowrt-firmware/blob/master/files/opt/mesh/templates/etc/config/uhttpd) - configurations for the uhttp server daemon (uhttpd = micro http daemon), points requests made on port 80 to the `/www/` folder where the admin dashboard is stored
* [wireless](https://github.com/sudomesh/sudowrt-firmware/blob/master/files/opt/mesh/templates/etc/config/wireless) - sets up physical radio interfaces (channel, power, SSIDs, BSSIDs, encryption) and binds them to interfaces created by the network configuration.

In addition, to UCI configurations, there are two scripts that use the bash configurations stored in [/etc/sudomesh/](https://github.com/sudomesh/sudowrt-firmware/tree/master/files/opt/mesh/templates/etc/sudomesh)  
* [/etc/udhcpc.user](https://github.com/sudomesh/sudowrt-firmware/blob/master/files/opt/mesh/templates/etc/udhcpc.user) - this file is triggered by DHCP events on the WAN interface (i.e. your home node getting an IP address from your home router or a DHCP server somewhere on your LAN). It checks for an l2tp tunnel and a route to an exit node through that tunnel and then triggers the next script.  
* [/etc/init/d/meshrouting](https://github.com/sudomesh/sudowrt-firmware/blob/master/files/opt/mesh/templates/etc/init.d/meshrouting) - this configures the firewall and sets up all of the routing rules for the home node. It makes sure that no packets slip from your private home network to the public mesh network. It then restarts tunneldigger and babeld.  

The default usernames, passwords, and access levels are set by the [passwd](https://github.com/sudomesh/sudowrt-firmware/blob/master/files/etc/passwd) and [shadow](https://github.com/sudomesh/sudowrt-firmware/blob/master/files/etc/shadow) files. Shadow contains an MD5 hash of the default password, which is `meshtheplanet`. This should be changed immeadiately after the autoconf process completes by running `passwd root` and `passwd admin`.  

# Building this firmware

The openwrt wiki has some examples of requirements per distro:
http://wiki.openwrt.org/doc/howto/buildroot.exigence#examples.of.package.installations

## the "super-easy" way
If you'd rather not use your personal computer to build this firmware, you can create a dedicated build machine out of any Ubuntu 16.04 server (e.g. a droplet on digitalocean, or a server on the mesh). Note: the server should have at least 50GB of storage, otherwise, the docker container will become to large for your server.

Clone this repository on your local machine.  

Now run:
```
ssh root@[ip build machine] 'bash -s' < create_build_machine.sh
``` 
This should automatically set a build to run every night at midnight (note: this still needs to be tested)  

If you would like to manually trigger a build, run the following:
```
ssh root@[ip build machine] '/opt/sudowrt-firmware/auto_build > /var/log/build.log 2>&1 &'
```
This will run the build in background on the server and produce no output. If you would like to see if your build started correctly, you can ssh into you server and ```tail -f /var/log/build.log```. You should be greeted with a familiar wall of text.

Now go to https://peoplesopen.net/walkthrough and follow the instructions to flash the firmware onto your router.

## the "easy" way
If you'd like to build the firmware in a controlled/clean environment, you can use [docker](https://docker.io) with the provided [Dockerfile](./Dockerfile) or a prebuilt image hosted on [our docker-hub](https://hub.docker.com/r/sudomesh/sudowrt-firmware/tags/).  
Docker provides good instructions for [installing docker-ce on Ubuntu](https://docs.docker.com/install/linux/docker-ce/ubuntu/) or [Debian](https://docs.docker.com/install/linux/docker-ce/debian/) as well as other operating systems.  

First clone this repository:

```
git clone https://github.com/sudomesh/sudowrt-firmware
cd sudowrt-firmware
```

To build and run the image (depending on your network connect and hardware, the build takes a couple of hours): 

Collect all the sudowrt-firmware dependencies into a docker image using:
```
docker build -t sudomesh/sudowrt-firmware .
```

or re-use a pre-built one using
```
docker pull sudomesh/sudowrt-firmware:0.2.3
```

After creating the container image, build the ar71xx and ar71xx.extender-node firmware using: 
```
docker run --rm -v $PWD/firmware_images:/firmware_images sudomesh/sudowrt-firmware:0.2.3
``` 

This command executes [entrypoint.sh](./entrypoint.sh) in the docker container. If the process completes successfully, the built firmware images `/firmware_images` directory of the repo. For some history on this topics please see https://github.com/sudomesh/sudowrt-firmware/issues/110 and https://github.com/sudomesh/sudowrt-firmware/issues/105 . 

Note that building with ```docker run --net=none -v $PWD/firmware_images:/firmware_images sudomesh/sudowrt-firmware``` disables network connections and prevents (uncontrolled) external resources from getting pulled into the build process. Necessary external resources are pulled into the build image when building the sudowrt/firmware image. Ideally, the container images contains all external dependencies, however some works needs to be done to make this a reality (see https://github.com/sudomesh/sudowrt-firmware/issues/116).

If the build fails, capture the console output, yell loudly, talk to someone or create [a new issue](https://github.com/sudomesh/meshwrt-firmware/issues/new).

### Docker debugging
The [entrypoint.sh](./entrypoint.sh) should make it easy to automate the build process. However, when debugging the build scripts, it might be useful to poke around a build machine container using ```docker run -it --entrypoint=/bin/bash sudomesh/sudowrt-firmware:latest -i``` . This will start an interactive terminal which allows for manually running/debugging scripts like ./build_only .  

### Docker clean-up
After finishing a build or before rerunning the build, it may be a good idea to remove any old docker containers and images. To remove all old containers and images, run the following commands:  
```
docker rm $(docker ps -a -q)
docker rmi $(docker images -q)
```
Note this will indiscriminately delete all docker containers and images. If you'd only like to remove select ones, replace the second part of both commands with the container and images ids, respectively. Perhaps this clean-up step could be automated, for discussion on this see https://github.com/sudomesh/sudowrt-firmware/issues/119 .  

Now go to https://peoplesopen.net/walkthrough and follow the instructions to flash the firmware onto your router.

## the "hard" way
If you'd rather build the firmware without Docker, please keep reading.

Unless you know what you are doing, you should build this on a Ubuntu 64bit box/container. At time of writing (Jan 2017), the [build script does not appear to work on Ubuntu 16.04](https://github.com/sudomesh/sudowrt-firmware/issues/103). 

Be aware that it won't build as root, so if you need to, follow [these instructions](https://www.digitalocean.com/community/tutorials/how-to-add-and-delete-users-on-an-ubuntu-14-04-vps) to create a non-root user, and give it the power to sudo.

Once you're logged in as a non-root user with sudo ability, install the neccesary dependencies:

```shell
sudo apt-get update
sudo apt-get install build-essential subversion libncurses5-dev zlib1g-dev gawk gcc-multilib flex git-core gettext quilt ccache libssl-dev xsltproc unzip python wget
```

Now go to https://peoplesopen.net/walkthrough and follow the instructions to flash the firmware onto your router.

### Building home-node firmware

Note: The below sections may no longer be relevant as they have not been sufficiently tested since build script refactor. 

Run:

```
 ./build <arch>
```

Where arch is either ar71xx or atheros e.g:

```
./build ar71xx
```

The build will happen in:

```
built_firmware/builder.ar71xx/
```

The firmware images will be available in:

```
built_firmware/builder.ar71xx/bin/ar71xx/
```

### Building extender-node firmware

Make sure you've already built the home-node firmware as the extender-node firmware will not build otherwise.

Run:

```
./build_extender-node ar71xx
```

The build will happen in:

```
built_firmware/builder.ar71xx.extender-node/
```

The firmware images will be available in:

```
built_firmware/builder.ar71xx.extender-node/bin/ar71xx/
```

# Stuff to check after building a new version of this firmware

After building a new version of the firmware, you should first make sure you can flash the target device(s). Then check the following:

* do nodes get a mesh ip
* do nodes tunnel to an exitnode
* do nodes babel with other nodes (both physically via ad-hoc interface and virtually via tunnel)
* do nodes successfully assign IPs and network w/ extenders on ports 1 and 2
* do ports 3 and 4 work as expected (i.e. do they provide access to the private / public networks respectively)
* do wireless clients get a WAN connection on the private SSID
* do wireless clients get a WAN connection on the public SSID
* does the retrieve_ip script clean itself up
* can nodes be reconfigured with makenode v0.0.1
* can the zeroconf script be re-run manually with a new (or the same) IP
* does the [admin panel](https://github.com/sudomesh/peoplesopen-dash) work (with default pw and changed pw)
* does the default root password expire after a day
* are the instructions provided in zeroconf_succeeded text helpful... :)

# Rebuilding firmware

The untested rebuild script was removed in [this commit](https://github.com/sudomesh/sudowrt-firmware/commit/78c7293bc4ac1d39d28311234a6a1ddb72f9c2c3).
Further investigation needs to be done as to how to expedite the build process and prevent it from rebuilding the OpenWrt toolchain on every build.
