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
if [ $? -ne 0 ]; then
    echo "[ERROR] Installation of SDL failed. Deployment aborted." > /dev/stderr
    exit 1
else
    echo "[INFO] Installation of SDL succeeded."
fi

########################################
# Build binaries
./build.sh
if [ $? -ne 0 ]; then
    echo "[ERROR] Build failed. Deployment aborted." > /dev/stderr
    exit 1
else
    echo "[INFO] Build succeeded."
fi

########################################
# Test binaries
Scripts/test_binaries.sh
if [ $? -ne 0 ]; then
    echo "[ERROR] Some tests failed. Deployment aborted." > /dev/stderr
    exit 1
else
    echo "[INFO] All tests passed."
fi

########################################
# Finish
echo "[INFO] All tests passed. Deployment successful."

# Only remove deployment directory if build was successful
cd "$ROOT_DIR"
rm -rf deployment
echo "[INFO] Deployment directory removed."
exit 0