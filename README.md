# Docker-Caroll
A thin wrapper for `perfect-dark` and `gepdexplorer`

Tested on MacOS, Ubuntu, and WSL+Docker hosts.

## Setup

`docker-caroll` has no dependencies beyond docker and python3.

``` bash
git clone git@gitlab.com:NeonNyan/docker-caroll.git ~/src/docker-caroll #or wherever
cd ~/src/docker-caroll
make # build the docker image
echo 'export PATH="$HOME/src/docker-caroll:$PATH"' >> ~/.profile # or whatever shell you use

```

## Usage

``` bash
cd ~/src/perfect-dark
pd make extract
pd make -j rom
```

