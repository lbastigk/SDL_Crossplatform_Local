#!/bin/bash

######################################
# Package installation script 
# for SDL Crossplatform
######################################

######################################
# We check each package manager for 
# existence via its command

# Debian-based (apt)
if command -v apt-get >/dev/null; then
    PACKAGE_MANAGER="apt"
# Fedora-based (dnf)
elif command -v dnf >/dev/null; then
    PACKAGE_MANAGER="dnf"
# Unsupported package manager
else
    echo "Unsupported package manager. Please install dependencies manually."
    sleep 5
    PACKAGE_MANAGER="unknown"
fi


# Define package lists for each distro
# TODO: This is just copied from Nebulite, proably too many packages
#       Refine this list to only what is necessary for SDL2 builds
APT_PACKAGES="cmake automake build-essential autoconf libtool m4 perl mingw-w64 gcc-mingw-w64 g++-mingw-w64 python3 python3-pip python3-numpy libasound2-dev libpulse-dev"
DNF_PACKAGES="cmake automake @development-tools autoconf libtool m4 perl mingw64-gcc mingw64-gcc-c++ python3 python3-pip python3-numpy alsa-lib-devel pulseaudio-libs-devel"

# Install packages based on detected package manager
case $PACKAGE_MANAGER in
    "apt-get")
        sudo apt-get update
        sudo apt-get install -y $APT_PACKAGES
        ;;
    "dnf")
        sudo dnf install -y $DNF_PACKAGES
        ;;
    *)
        echo "Unsupported package manager. Please install dependencies manually."
        ;;
esac