#!/bin/bash

######################################
# Install script for SDL Crossplatform
######################################
if [ "$EUID" -eq 0 ]; then
  echo "This script should NOT be run as root or with sudo. Please run as a regular user."
  exit 1
fi


######################################
# Make all scripts executable
chmod +x Scripts/*.sh

######################################
# Package installation
Scripts/package_installation.sh

######################################
# Initialize git submodules
git submodule update --init --recursive