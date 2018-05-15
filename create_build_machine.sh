#!/bin/sh

set -x
set -e

SUDOWRT_REPO=sudomesh/sudowrt-firmware
SUDOWRT_DIR=/opt/sudowrt-firmware
CRON_TIME="00 00"

DEBIAN_FRONTEND=noninteractive apt-get update

DEBIAN_FRONTEND=noninteractive apt-get install -yq --force-yes \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

DEBIAN_FRONTEND=noninteractive add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

DEBIAN_FRONTEND=noninteractive apt-get update

DEBIAN_FRONTEND=noninteractive apt-get install -yq --force-yes \
    docker-ce


git clone https://github.com/${SUDOWRT_REPO} ${SUDOWRT_DIR}


echo "${CRON_TIME} * * * ${SUDOWRT_DIR}/auto_build" >> new_cron

crontab new_cron
rm new_cron

exit 0
