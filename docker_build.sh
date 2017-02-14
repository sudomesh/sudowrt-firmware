#!/bin/bash

architecture=$1
if [ -z "$architecture" ]
then
  architecture="ar71xx"
fi
time ./build $architecture
mkdir -p ./firmware_images
echo "BUILT FILES: "
ls ./built_firmware/builder.ar71xx/bin/ar71xx/
cp -r ./built_firmware/builder.ar71xx/bin/ar71xx/ /firmware_images
