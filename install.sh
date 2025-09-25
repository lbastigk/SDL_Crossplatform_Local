#!/bin/bash

######################################
# Install script for SDL Crossplatform
######################################
PROJECT_ROOT="$(pwd)"

######################################
# Ensure the script is not run as root
if [ "$EUID" -eq 0 ]; then
  echo "This script should NOT be run as root or with sudo. Please run as a regular user."
  exit 1
fi

######################################
# Make all scripts executable
chmod +x Scripts/SDL2_build/*.sh

######################################
# Package installation
Scripts/SDL2_build/package_installation.sh

######################################
# Ensure a clean build environment
cd "$PROJECT_ROOT"
rm -rf external
rm -rf build

mkdir -p build
mkdir -p build/logs
mkdir -p build/SDL2
mkdir -p external

######################################
# Initialize git submodules
echo "[INFO] Initializing git submodules..."
git submodule update --init --recursive > /dev/null 2>&1
echo "[INFO] Git submodules initialized."

####################################
# Submodules: SDL
# Creates builds:
# ./build/SDL2/static_linux/
# ./build/SDL2/shared_linux/
# ./build/SDL2/shared_windows/

echo "[INFO] Starting SDL2 builds..."

# Static Linux build
echo "[INFO] Building SDL2 static-linux..."
cd "$PROJECT_ROOT"
Scripts/SDL2_build/build_sdl.sh linux core ttf image > /dev/null 2>&1 \
|| { echo "[ERROR] SDL2 static-linux build failed" > /dev/stderr; exit 1; }
echo "[INFO] SDL2 static-linux build completed."

# Shared Windows build
echo "[INFO] Building SDL2 shared-windows..."
cd "$PROJECT_ROOT"
Scripts/SDL2_build/build_sdl.sh windows core ttf image > /dev/null 2>&1 \
|| { echo "[ERROR] SDL2 shared-windows build failed" > /dev/stderr; exit 1; }
echo "[INFO] SDL2 shared-windows build completed."

####################################
# Reset 
cd "$PROJECT_ROOT"
Scripts/SDL2_build/reset_sdl_submodules.sh > /dev/null 2>&1 \
|| { echo "[ERROR] SDL2 submodule reset failed" > /dev/stderr; exit 1; }

####################################
# Uninitialize git submodules
git submodule deinit -f --all           > /dev/null 2>&1

####################################
# Finished
echo "[INFO] All builds completed successfully."