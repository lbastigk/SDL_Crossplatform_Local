#!/bin/bash

######################################
# Build shared SDL2 library for Windows (DLLs) using MinGW
######################################

######################################
# Prerequisites

# Check if MinGW is installed
if ! command -v x86_64-w64-mingw32-gcc &> /dev/null; then
    echo "[ERROR] MinGW-w64 not found. Please install: sudo apt-get install mingw-w64" > /dev/stderr
    exit 1
fi

# Reset hard
Scripts/SDL2_build/reset_sdl_submodules.sh

# Set up paths
PROJECT_ROOT="$(pwd)"
INSTALLATION_PATH="$PROJECT_ROOT/build/SDL2/shared_windows"

# Clean previous build
rm -rf "$INSTALLATION_PATH"
mkdir -p "$INSTALLATION_PATH"

######################################
# 1.) SDL2
echo "[INFO] Building SDL2 shared-windows (DLLs)"

# Navigate to SDL2 source directory
cd "$PROJECT_ROOT/external/SDL2"

# Clean and prepare
[ -f Makefile ]  && { make clean > /dev/null 2>&1 || true; }
[ -f configure ] || ./autogen.sh > /dev/null 2>&1

# Build
./configure --prefix="${INSTALLATION_PATH}" \
    --host=x86_64-w64-mingw32 \
    --enable-shared \
    --disable-static \
    --disable-video-wayland \
    --disable-video-x11 \
    --disable-video-opengl \
    --disable-video-opengles \
    --disable-pulseaudio \
    --disable-alsa \
    --disable-oss \
    CC=x86_64-w64-mingw32-gcc \
    CXX=x86_64-w64-mingw32-g++ \
    AR=x86_64-w64-mingw32-ar \
    RANLIB=x86_64-w64-mingw32-ranlib \
    STRIP=x86_64-w64-mingw32-strip
make -j"$(nproc)" || { echo "[ERROR] SDL2 shared-windows failed at make"    > /dev/stderr; exit 1; }
make install      || { echo "[ERROR] SDL2 shared-windows failed at install" > /dev/stderr; exit 1; }

# Check if SDL2 dll exists
if [ ! -f "$INSTALLATION_PATH/bin/SDL2.dll" ]; then
    echo "[ERROR] SDL2.dll not found after build!" > /dev/stderr
    exit 1
fi

######################################
# 2.) SDL2_image
echo ""
echo "---------------------------------------------------"
echo "[INFO] Building SDL2_image shared-windows (DLLs)"

# Navigate to SDL2_image source directory
cd "$PROJECT_ROOT/external/SDL2_image"

# Clean and prepare
[ -f Makefile ]  && { make clean > /dev/null 2>&1 || true; }
[ -f configure ] || ./autogen.sh > /dev/null 2>&1

# Build
./configure --prefix="${INSTALLATION_PATH}" \
    --host=x86_64-w64-mingw32 \
    --with-sdl-prefix="$INSTALLATION_PATH" \
    --enable-shared \
    --disable-static \
    CC=x86_64-w64-mingw32-gcc \
    CXX=x86_64-w64-mingw32-g++ \
    AR=x86_64-w64-mingw32-ar \
    RANLIB=x86_64-w64-mingw32-ranlib \
    STRIP=x86_64-w64-mingw32-strip
make -j"$(nproc)" || { echo "[ERROR] SDL2_image shared-windows failed at make"    > /dev/stderr; exit 1; }
make install      || { echo "[ERROR] SDL2_image shared-windows failed at install" > /dev/stderr; exit 1; }

# Check if SDL2_image dll exists
if [ ! -f "$INSTALLATION_PATH/bin/*image*.dll" ]; then
    echo "[ERROR] SDL2_image.dll not found after build!" > /dev/stderr
    exit 1
fi

######################################
# 3.) SDL2_ttf
echo ""
echo "---------------------------------------------------"
echo "[INFO] Building SDL2_ttf shared-windows (DLLs)"

# Navigate to SDL2_ttf source directory
cd "$PROJECT_ROOT/external/SDL2_ttf"

# Clean and prepare
[ -f Makefile ]  && { make clean > /dev/null 2>&1 || true; }
[ -f configure ] || ./autogen.sh > /dev/null 2>&1

# Build
./configure --prefix="${INSTALLATION_PATH}" \
    --host=x86_64-w64-mingw32 \
    --with-sdl-prefix="$INSTALLATION_PATH" \
    --enable-shared \
    --disable-static \
    CC=x86_64-w64-mingw32-gcc \
    CXX=x86_64-w64-mingw32-g++ \
    AR=x86_64-w64-mingw32-ar \
    RANLIB=x86_64-w64-mingw32-ranlib \
    STRIP=x86_64-w64-mingw32-strip
make -j"$(nproc)" || { echo "[ERROR] SDL2_ttf shared-windows failed at make"    > /dev/stderr; exit 1; }
make install      || { echo "[ERROR] SDL2_ttf shared-windows failed at install" > /dev/stderr; exit 1; }

# Check if SDL2_ttf dll exists
if [ ! -f "$INSTALLATION_PATH/bin/*ttf*.dll" ]; then
    echo "[ERROR] SDL2_ttf.dll not found after build!" > /dev/stderr
    exit 1
fi

######################################
# Summary
echo "[INFO] SDL2 shared-windows build completed successfully!"
echo "[INFO] Windows DLLs installed in: $INSTALLATION_PATH"
