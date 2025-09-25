#!/bin/bash
ROOT_DIR="$(pwd)"
rm -rf deployment
mkdir -p deployment

########################################
# Clone
cd deployment
git clone https://github.com/lbastigk/SDL_Crossplatform_Local.git
cd SDL_Crossplatform_Local

########################################
# Install
echo "[INFO] Installing SDL"
./install.sh

# Check if the build was successful
if [ $? -ne 0 ]; then
    echo "[ERROR] Installation of SDL failed. Deployment aborted." > /dev/stderr
    exit 1
else
    echo "[INFO] Installation of SDL succeeded."
fi

########################################
# Build binaries
cd "$ROOT_DIR"
./build.sh
if [ $? -ne 0 ]; then
    echo "[ERROR] Build failed. Deployment aborted." > /dev/stderr
    exit 1
else
    echo "[INFO] Build succeeded."
fi

########################################
# Test binaries
function test_binary() {
    local binary_path="$1"
    if [ -f "$binary_path" ]; then
        "$binary_path" --version > /dev/null 2>&1
        if [ $? -ne 0 ]; then
            echo "[ERROR] Test of $binary_path failed. Deployment aborted." > /dev/stderr
            exit 1
        else
            echo "[INFO] Test of $binary_path succeeded."
        fi
    else
        echo "[ERROR] Binary $binary_path not found. Deployment aborted." > /dev/stderr
        exit 1
    fi
}

test_binary "./bin/SDL_Example"
test_binary "./bin/SDL_Example_Debug"
test_binary "wine ./bin/SDL_Example.exe"
test_binary "wine ./bin/SDL_Example_Debug.exe"

########################################
# Finish
echo "[INFO] All tests passed. Deployment successful."

# Only remove deployment directory if build was successful
cd "$ROOT_DIR"
rm -rf deployment
echo "[INFO] Deployment directory removed."
exit 0