#!/bin/bash

######################################
# Build static SDL2 library for Linux
######################################

######################################
# Prerequisites

# Reset hard
Scripts/SDL2_build/reset_sdl_submodules.sh

# Set up paths
PROJECT_ROOT="$(pwd)"
INSTALLATION_PATH="$PROJECT_ROOT/build/SDL2/static_linux"

# Clean previous build
rm -rf "$INSTALLATION_PATH"
mkdir -p "$INSTALLATION_PATH"

######################################
# 1.) SDL2
echo "[INFO] Building SDL2 static-linux"

# Navigate to SDL2 source directory
cd "$PROJECT_ROOT/external/SDL2"

# Clean and prepare
[ -f Makefile ]  && { make clean > /dev/null 2>&1 || true; }
[ -f configure ] || ./autogen.sh > /dev/null 2>&1

# Build
./configure --prefix="${INSTALLATION_PATH}" \
    --enable-static \
    --disable-shared CFLAGS=-fPIC
make -j"$(nproc)" || { echo "[ERROR] SDL2 static-linux failed at make"    > /dev/stderr; exit 1; }
make install      || { echo "[ERROR] SDL2 static-linux failed at install" > /dev/stderr; exit 1; }

######################################
# 2.) SDL2_image
echo "[INFO] Building SDL2_image static-linux"

# Navigate to SDL2_image source directory
cd "$PROJECT_ROOT/external/SDL2_image"

# Clean and prepare
[ -f Makefile ]  && { make clean > /dev/null 2>&1 || true; }
[ -f configure ] || ./autogen.sh > /dev/null 2>&1

# Build
./configure --prefix="${INSTALLATION_PATH}" \
    --with-sdl-prefix="$INSTALLATION_PATH" \
    --enable-static \
    --disable-shared CFLAGS=-fPIC
make -j"$(nproc)" || { echo "[ERROR] SDL2_image static-linux failed at make"    > /dev/stderr; exit 1; }
make install      || { echo "[ERROR] SDL2_image static-linux failed at install" > /dev/stderr; exit 1; }

######################################
# 3.) SDL2_ttf
echo "[INFO] Building SDL2_ttf static-linux"

# Navigate to SDL2_ttf source directory
cd "$PROJECT_ROOT/external/SDL2_ttf"

# Clean and prepare
[ -f Makefile ]  && { make clean > /dev/null 2>&1 || true; }
[ -f configure ] || ./autogen.sh > /dev/null 2>&1

# Build
./configure --prefix="${INSTALLATION_PATH}" \
    --with-sdl-prefix="$INSTALLATION_PATH" \
    --enable-static \
    --disable-shared CFLAGS=-fPIC
make -j"$(nproc)" || { echo "[ERROR] SDL2_ttf static-linux failed at make"    > /dev/stderr; exit 1; }
make install      || { echo "[ERROR] SDL2_ttf static-linux failed at install" > /dev/stderr; exit 1; }

######################################
# Summary
echo "[INFO] SDL2 static-linux build completed successfully!"
echo "[INFO] Libraries installed in: $INSTALLATION_PATH"
