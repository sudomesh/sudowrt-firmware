The sudo mesh firmware builder.

What the prepare script does:

1. Downloads OpenWRT

2. Patches OpenWRT with sudo mesh patches.

3. Adds a feed to get OpenWRT to pull in the sudomesh/openwrt-packages feed from github.
The openwrt-packages contains references to the code for the actual sudo mesh openwrt-packages
(that each have their own github repositories).

# Usage

## Requirements

    sudo aptitude install build-essential git subversion quilt cmake libncurses5-dev

## Build All

Build firmware and all packages from scratch:

    git clone https://github.com/sudomesh/sudowrt-firmware.git
    cd sudowrt-firmware
    ./prepare
    ./build

Something magical will appear, this is the sudowrt-firmware, under e.g. `built_firmware/atheros/bin/`

## Build Packages

You can re-build individual packages more quickly and easily with `build_package`, such as:

    build_package -a atheros internetisdownredirect
