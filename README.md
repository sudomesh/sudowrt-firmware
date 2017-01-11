The sudo mesh firmware builder.

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
```
docker build -t sudomesh/sudowrt-firmware:dev . 
docker run -v $PWD/built_firmware:/usr/local/sudowrt-firmware/built_firmware -t sudomesh/sudowrt-firmware:dev
``` 

A successful build should put the built firmware image in ./built_firmware of the repo directory. The console output should look something like:

```
(please add output)
```

Now got to https://sudoroom.org/wiki/Mesh/WalkThrough to flash the firmware onto your router.
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

The rebuild script is untested!

You can use ./rebuild but we're not actually sure what you can safely change and still use the ./rebuild script successfully. Changing packages, feeds and stuff in files/ should work, but if you change the patches then you will have to do a full rebuild.
