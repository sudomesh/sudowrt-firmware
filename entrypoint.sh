#!/bin/bash

build="build"
architecture=$1
directory="ar71xx"
if [ -z "$architecture" ]
then
  architecture="ar71xx"
elif [ "$architecture" = "ar71xx.extender-node" ]
then
  build="build_extender-node"
  directory="ar71xx.extender-node"
fi

time ./build ar71xx
time ./build_extender-node ar71xx
mkdir -p ./firmware_images
read -p "Check for home node images"
cp -r ./built_firmware/builder.ar71xx/bin/ar71xx/ /firmware_images
read -p "Check for extender node images"
cp -r ./built_firmware/builder.ar71xx.extender-node/bin/ /firmware_images
