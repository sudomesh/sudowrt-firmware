#!/bin/bash
ARCH=ar71xx
time ./build $ARCH
time ./build_extender-node $ARCH

mkdir -p ./firmware_images
cp -r ./built_firmware /firmware_images
