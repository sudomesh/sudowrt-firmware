FROM ubuntu:14.04
RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -yq \
      build-essential=11.6ubuntu6 \
      subversion=1.8.8-1ubuntu3.3 \
      libncurses5-dev=5.9+20140118-1ubuntu1 \
      zlib1g-dev=1:1.2.8.dfsg-1ubuntu1.1 \
      gawk=1:4.0.1+dfsg-2.1ubuntu2 \
      gcc-multilib=4:4.8.2-1ubuntu6 \
      flex=2.5.35-10.1ubuntu2 \
      git-core=1:1.9.1-1ubuntu0.8 \
      gettext=0.18.3.1-1ubuntu3 \
      quilt=0.61-1 \
      ccache=3.1.9-1 \
      libssl-dev=1.0.1f-1ubuntu2.26 \
      xsltproc=1.1.28-2build1 \
      unzip=6.0-9ubuntu1.5 \
      python=2.7.5-5ubuntu3 \
      wget=1.15-1ubuntu1.14.04.4
RUN apt-get clean

ENV FIRMWARE_DIR /usr/local/sudowrt-firmware
WORKDIR $FIRMWARE_DIR
COPY . $FIRMWARE_DIR
RUN ./build ar71xx
ENTRYPOINT ["./entrypoint.sh"]
