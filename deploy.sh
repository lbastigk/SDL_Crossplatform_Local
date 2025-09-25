#!/bin/bash
rm -rf deployment
mkdir -p deployment

cd deployment
git clone https://github.com/lbastigk/SDL_Crossplatform_Local.git
cd SDL_Crossplatform_Local
./install.sh