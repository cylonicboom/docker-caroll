FROM ubuntu:20.04
ENV LANG=en_US.UTF-8
# build packages for perfect-dark
# gepdextractor dependencies
RUN apt-get update && apt-get install -y \
binutils-mips-linux-gnu make vim python3-pip python-jinja2

# set sauce symlink workdir
WORKDIR /pd
