#!/bin/bash
ROOT_DIR="$(pwd)"
rm -rf deployment
mkdir -p deployment

# Clone
cd deployment
git clone https://github.com/lbastigk/SDL_Crossplatform_Local.git
cd SDL_Crossplatform_Local

# Inform about last commit
echo "[INFO] Last commit in repository:"
git log -1 --oneline

# Build the project
echo "[INFO] Starting build process..."
./install.sh

# Check if the build was successful
if [ $? -ne 0 ]; then
    echo "[ERROR] Build failed. Deployment aborted." > /dev/stderr
    exit 1
else
    echo "[INFO] Build succeeded. Deployment completed."
fi

# Only remove deployment directory if build was successful
cd "$ROOT_DIR"
rm -rf deployment
echo "[INFO] Deployment directory removed."
exit 0