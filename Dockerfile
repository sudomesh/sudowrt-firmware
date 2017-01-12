FROM ubuntu:14.04
RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -yq build-essential subversion libncurses5-dev zlib1g-dev gawk gcc-multilib flex git-core gettext quilt ccache libssl-dev xsltproc unzip python wget
RUN apt-get clean
RUN git clone https://github.com/sudomesh/sudowrt-firmware.git /usr/local/sudowrt-firmware
WORKDIR /usr/local/sudowrt-firmware
ENTRYPOINT ["./build", "ar71xx"]
