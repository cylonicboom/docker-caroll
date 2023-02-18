FROM docker.io/ubuntu:20.04 as build-armips
ENV LANG=en_US.UTF-8
# Fix timezone issue
ENV TZ=UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN apt-get update && apt-get install -y \
cmake git g++-multilib
WORKDIR /tmp
RUN git clone --recursive https://github.com/Kingcom/armips.git && cd armips && \
mkdir build && cd build && cmake .. && cmake --build . --config Release && cp armips /usr/bin

FROM docker.io/ubuntu:22.10
ENV LANG=en_US.UTF-8
# Fix timezone issue
ENV TZ=UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# pwsh + psake
WORKDIR /tmp

run apt-get update && apt-get install -y wget
# pasted and modified from msdn pwsh install page
run wget https://github.com/PowerShell/PowerShell/releases/download/v7.2.6/powershell-lts_7.2.6-1.deb_amd64.deb && dpkg -i powershell-lts_7.2.6-1.deb_amd64.deb || apt-get -fy install

run apt-get install -y git
# can containers start other containers?
# if so than I can make another image for psake
run git clone https://github.com/psake/psake.git /opt/psake

add psake/run-psake /usr/bin


# build packages for perfect-dark
# gepdextractor dependencies
# mingw: mouseinjector dependencies
RUN apt-get update && apt-get install -y \
binutils-mips-linux-gnu make vim python3-pip python3-jinja2 \
g++-multilib libc6-dev-i386 libcapstone4 libcapstone-dev \
binutils-mingw-w64-i686 g++-mingw-w64-i686 \
gcc-mingw-w64-base gcc-mingw-w64-i686 mingw-w64-common \
mingw-w64-i686-dev mingw-w64-tools curl python-is-python3 \
zip unzip rsync jq git strace php

RUN apt-get update &&  apt-get install -y xdelta

# armips
COPY --from=build-armips /usr/bin/armips /usr/bin/armips

ENV PATH="/app/pdtools/bin:$PATH"

# set sauce symlink workdir
WORKDIR /pd

RUN apt-get update && apt-get install -y gcc-mips-linux-gnu

RUN apt-get update && apt-get install -y wine mono-complete

