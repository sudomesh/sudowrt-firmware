A sudomesh firmware builder.

[![Build Status](https://travis-ci.org/sudomesh/sudowrt-firmware.svg?branch=master)](https://travis-ci.org/sudomesh/sudowrt-firmware)

# Requirements

The openwrt wiki has some examples of requirements per distro:
http://wiki.openwrt.org/doc/howto/buildroot.exigence#examples.of.package.installations

# the "easy" way
If you'd like to build the firmware in a controlled/clean environment, you can use [docker](https://docker.io) with the provided [Dockerfile](./Dockerfile):

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
docker pull sudomesh/sudowrt-firmware:0.2.1
```

After creating the container image, build the ar71xx and ar71xx.extender-node firmware using: 
```
docker run -v $PWD/firmware_images:/firmware_images sudomesh/sudowrt-firmware:0.2.1
``` 

This command executes [entrypoint.sh](./entrypoint.sh) in the docker container. If the process completes successfully, the built firmware images `/firmware_images` directory of the repo. For some history on this topics please see https://github.com/sudomesh/sudowrt-firmware/issues/110 and https://github.com/sudomesh/sudowrt-firmware/issues/105 . 

Note that building with ```docker run --net=none -v $PWD/firmware_images:/firmware_images sudomesh/sudowrt-firmware``` disables network connections and prevents (uncontrolled) external resources from getting pulled into the build process. Necessary external resources are pulled into the build image when building the sudowrt/firmware image. Ideally, the container images contains all external dependencies, however some works needs to be done to make this a reality (see https://github.com/sudomesh/sudowrt-firmware/issues/116).

If the build fails, capture the console output, yell loudly, talk to someone or create [a new issue](https://github.com/sudomesh/meshwrt-firmware/issues/new).

## Docker debugging
The [entrypoint.sh](./entrypoint.sh) should make it easy to automate the build process. However, when debugging the build scripts, it might be useful to poke around a build machine container using ```docker run -it --entrypoint=/bin/bash sudomesh/sudowrt-firmware:latest -i``` . This will start an interactive terminal which allows for manually running/debugging scripts like ./build_only .  

## Docker clean-up
After finishing a build or before rerunning the build, it may be a good idea to remove any old docker containers and images. To remove all old containers and images, run the following commands:  
```
docker rm $(docker ps -a -q)
docker rmi $(docker images -q)
```
Note this will indiscriminately delete all docker containers and images. If you'd only like to remove select ones, replace the second part of both commands with the container and images ids, respectively. Perhaps this clean-up step could be automated, for discussion on this see https://github.com/sudomesh/sudowrt-firmware/issues/119 .  

Now go to https://peoplesopen.net/walkthrough and follow the instructions to flash the firmware onto your router.

# the "hard" way
If you'd rather build the firmware without Docker, please keep reading.

Unless you know what you are doing, you should build this on a Ubuntu 64bit box/container. At time of writing (Jan 2017), the [build script does not appear to work on Ubuntu 16.04](https://github.com/sudomesh/sudowrt-firmware/issues/103). 

Be aware that it won't build as root, so if you need to, follow [these instructions](https://www.digitalocean.com/community/tutorials/how-to-add-and-delete-users-on-an-ubuntu-14-04-vps) to create a non-root user, and give it the power to sudo.

Once you're logged in as a non-root user with sudo ability, install the neccesary dependencies:

```shell
sudo apt-get update
sudo apt-get install build-essential subversion libncurses5-dev zlib1g-dev gawk gcc-multilib flex git-core gettext quilt ccache libssl-dev xsltproc unzip python wget
```

# Building home-node firmware

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

# Building extender-node firmware

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

# Rebuilding firmware

The untested rebuild script was removed in [this commit](https://github.com/sudomesh/sudowrt-firmware/commit/78c7293bc4ac1d39d28311234a6a1ddb72f9c2c3).
We are currently working on a new rebuild process using docker and travis. See issues [111](https://github.com/sudomesh/sudowrt-firmware/issues/111) and [116](https://github.com/sudomesh/sudowrt-firmware/issues/116).
