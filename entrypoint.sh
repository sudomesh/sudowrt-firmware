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
time ./$build $architecture
mkdir -p ./firmware_images
cp -r ./built_firmware/builder.$directory/bin/$directory/ /firmware_images
