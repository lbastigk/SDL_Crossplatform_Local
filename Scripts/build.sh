#!/bin/bash

################################################
# Check for sudo
if [ "$EUID" -eq 0 ]; then
  echo "This script should NOT be run as root or with sudo. Please run as a regular user."
  exit 1
fi
build_type="None"

################################################
# Check if ./install.sh has been run
if [ ! -d "./build/SDL2" ]; then
    echo "Please run ./install.sh first to set up the environment."
    exit 1
fi

################################################
# Create bin directory if it doesn't exist
if [ ! -d "./bin" ]; then
    mkdir -p ./bin
fi

################################################
# Enable strict error handling
set -Ee
trap 'echo ""; echo "[ERROR] Build failed on ${build_type}!"; echo "Consider running a full clean with make clean"; exit 1' ERR

################################################
# Parse arguments
minimal_build=false
if [[ "$1" == "-minimal" ]]; then
    minimal_build=true
fi

################################################
# Functions
function clean_src() {
    echo "Cleaning only SDL_Example object files and binaries"

    rm -rf "$1"

    OBJ_DIR="./build/$2/CMakeFiles/SDL_Example.dir/src/"
    if [ -d "$OBJ_DIR" ]; then
        find "$OBJ_DIR" -name '*.o' -delete
        find "$OBJ_DIR" -name '*.o.d' -delete
    else
        echo "No object directory found at $OBJ_DIR — skipping clean"
    fi
}

function build_debug() {
    clean_src "./build/debug/SDL_Example" "debug"
    cmake -DCMAKE_BUILD_TYPE=Debug -B ./build/debug -S .
    cmake --build ./build/debug -j$(nproc)
    cp ./build/debug/SDL_Example ./bin/SDL_Example_Debug
}

function build_release() {
    clean_src "./build/release/SDL_Example" "release"
    cmake -DCMAKE_BUILD_TYPE=Release \
          -DCMAKE_CXX_FLAGS_RELEASE="-O3 -DNDEBUG -march=native" \
          -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=TRUE \
          -B ./build/release -S .
    cmake --build ./build/release -j$(nproc)
    cp ./build/release/SDL_Example ./bin/SDL_Example
    strip "./bin/SDL_Example"
}


function build_debug_windows() {
      clean_src "./build/windows-debug/SDL_Example.exe" "windows-debug"
      cmake -DCMAKE_BUILD_TYPE=Debug \
            -DCMAKE_TOOLCHAIN_FILE="cmake/toolchains/application_build.cmake" \
            -B ./build/windows-debug -S .
      cmake --build ./build/windows-debug -j$(nproc)
      cp ./build/windows-debug/SDL_Example.exe ./bin/SDL_Example_Debug.exe
}

function build_release_windows() {
      clean_src "./build/windows-release/SDL_Example.exe" "windows-release"
      cmake -DCMAKE_BUILD_TYPE=Release \
            -DCMAKE_TOOLCHAIN_FILE="cmake/toolchains/application_build.cmake" \
            -B ./build/windows-release -S .
      cmake --build ./build/windows-release -j$(nproc)
      cp ./build/windows-release/SDL_Example.exe ./bin/SDL_Example.exe

      # Copy DLLs from the SDL2 install directory plus dependency bins into the application bin
      # CMake install places DLLs under build/SDL2/shared_windows/bin
      cp build/SDL2/shared_windows/bin/*.dll ./bin/ || true
      # Also copy dependency DLLs (freetype, harfbuzz, etc.) if present
      for d in build/SDL2/shared_windows/deps/*/bin; do
          if [ -d "$d" ]; then
              cp "$d"/*.dll ./bin/ 2>/dev/null || true
          fi
      done
}

#############################################################
# [BUILD]
rm -rf "./bin/SDL_Example"
rm -rf "./bin/SDL_Example_Debug"
rm -rf "./bin/SDL_Example.exe"
rm -rf "./bin/SDL_Example_Debug.exe"

echo "#############################################################"
echo ""
echo "Step 1: Building Linux release binary"
build_type="Linux Release"
build_release
echo "#############################################################"
echo ""
echo "Step 2: Building Linux debug binary"
build_type="Linux Debug"
build_debug

if [[ "$minimal_build" == false ]]; then
    echo "#############################################################"
    echo ""
    echo "Step 3: Building Windows release binary"
    build_type="Windows Release"
    build_release_windows

    echo "#############################################################"
    echo ""
    echo "Step 4: Building Windows debug binary"
    build_type="Windows Debug"
    build_debug_windows
fi

echo "Build done!"