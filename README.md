# Docker-Caroll
A gaggle of scripts inside a docker container that just wants to help you build `perfect-dark` and `gepdexplorer`

## Setup

The `pd` wrapper itself has no dependencies beyond docker, git, and a recent python version.

Dependencies for this project and perfect-dark will be downloaded and contained within the docker image.

``` bash
git clone git@gitlab.com:NeonNyan/docker-caroll.git ~/src/docker-caroll
cd ~/src/docker-caroll
make # build the docker image
echo 'export PATH="$HOME/src/docker-caroll:$PATH"' >> ~/.profile

```
### required environment variables

``` bash
# Perfect Dark tools
export PATH=$PATH:${HOME}/src/docker-caroll/bin
export PATH="$PATH:$HOME/src/pdtools/bin"


# decomp. docker-caroll uses this too.
export PD="$HOME/src/perfect-dark"
# decomp.
export PDTOOLS="$HOME/src/pdtools"
# docker-caroll
export MOUSEINJECTOR=${HOME}/src/MouseInjectorPlugin
# decomp: many tools claim this is optional but ymmv
export ROMID="ntsc-final"

# docker-caroll: psake scripts
export PDPSAKE=${HOME}/src/docker-caroll/scripts/psake
# docker-caroll:gepd installation root
export GEPD="${HOME}/.local/opt/1964"
# docker-caroll: location of latest gepd zip cache
export GEPD_ZIP="${HOME}/Downloads/1964_GEPD_Edition.zip"
# docker-caroll: location to place gepd bundles and fresh roms
export GEPD_ARCHIVE="${HOME}/.local/var/docker-caroll/archive"
# docker-caroll: location to install gepd bundle
export GEPD_TARGET="${HOME}/.local/opt/1964_mod"
# GameID of GEPD steam installation
export GEPD_STEAM_GAMEID="1234567890"
```

## Usage

``` bash
cd ~/src/perfect-dark
pd make extract
pd make -j rom

# drop into shell mounted into PD
pd bash

# defaults to --tasklist make-perfectdark
pd psake

# builds pd, builds mouse injector and makes a new gepd bundle (with no rom in archive)
pd psake --tasklist make-gepdbundle

# make a gepd bundle but pointed at a rom built by an arbitrary worktree
PD=~/src/perfect-dark-experimental pd psake --tasklist make-gepdbundle
```

## psake tasks

- `clean-perfectdark`
- `make-perfectdark`
- `clean-mouseinjector`
- `make-mouseinjector`
- `make-gepdbundle`



## building a custom MouseInjector bundle

The MouseInjectorPlugin is a Windows Dll purpose-built for, and bundled with, the [1964GEPD emulator for Goldeneye / Perfect Dark](https://github.com/Graslu/1964GEPD).

[My fork](https://gitlab.com/NeonNyan/mouseinjectorplugin) adds some tweaks to the makefile such that it will build from linux. Thus, with a properly configured setup we can do this:

``` bash
# build a speedrun build of the mouseinjector
SPEEDRUN_BUILD=1 pd psake --tasklist clean-mouseinjector,make-mouseinjector

# build a vanilla build of the mouseinjector, but in a different worktree
MOUSEINJECTOR=~/src/mouseinjector-experimental pd psake --tasklist clean-mouseinjector,make-mouseinjector
```

However, copying the dll to 1964 each time is inefficient and keeping track of iterations is a nightmare. The psake task `make-gepdbundle` exists to make this easier:
- requires a build of perfect-dark and mouseinjector
- Keeps a pristine zip of the latest GEPD bundle
- Extracts a copy, injects ini tweaks and our mouseinjector, repackages, and archives along with your old rom builds
- Cleans and reinstalls a sandbox GEPD installation that's always pointed at your most recent perfect-dark build

Note that the MouseInjector is setup for my particular keyboard and may bindings may not work as you expect.

## using psake outside of docker
This project's Dockerfile can be used as a reference implementation for building on a non-container.

Take care to also set `*_HOST` duplicate versions of path-like `docker-caroll` / `perfect-dark` - related environment variables (except SSH_AUTH)

