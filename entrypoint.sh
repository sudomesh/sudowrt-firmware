#!/bin/bash
ARCH="ar71xx"
TARGET="MYNETN600"
BUILD_DIR=./built_firmware/builder.$ARCH

# add commit hash to banners
GIT_COMMIT=$(git rev-parse HEAD)
sed -i "s/<hash>/$GIT_COMMIT/g" ./files/etc/banner
sed -i "s/<hash>/$GIT_COMMIT/g" ./files/opt/mesh/templates/etc/banner

# copy updated files from repo to build directory
rm -r $BUILD_DIR/files
cp -r ./files $BUILD_DIR/files

# execute rebuild of firmware
time ./build_pre $ARCH

mkdir -p ./firmware_images
cp -r $BUILD_DIR/bin/ar71xx /firmware_images/.
