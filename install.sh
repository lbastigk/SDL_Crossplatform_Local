#!/bin/bash

######################################
# Install script for SDL Crossplatform
######################################

######################################
# Ensure the script is not run as root
if [ "$EUID" -eq 0 ]; then
  echo "This script should NOT be run as root or with sudo. Please run as a regular user."
  exit 1
fi

######################################
# Make all scripts executable
chmod +x Scripts/SDL2_build/*.sh
chmod +x Scripts/SDL2_build/build_lib/*.sh

######################################
# Package installation
Scripts/SDL2_build/package_installation.sh

######################################
# Initialize git submodules
git submodule update --init --recursive

####################################
# Submodules: SDL
# Creates builds:
# ./build/SDL2/static_linux/
# ./build/SDL2/shared_linux/
# ./build/SDL2/shared_windows/

# Static Linux build
mkdir -p build/SDL2/static_linux
Scripts/SDL2_build/build_lib/static_linux.sh

# Shared Linux build
mkdir -p build/SDL2/shared_linux
Scripts/SDL2_build/build_lib/shared_linux.sh

# Shared Windows build
mkdir -p build/SDL2/shared_windows
Scripts/SDL2_build/build_lib/shared_windows.sh