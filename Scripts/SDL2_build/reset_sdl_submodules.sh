#!/bin/bash

######################################
# Only reset SDL submodules
######################################

cd external/SDL2
git reset --hard
git clean -fdx

cd ../SDL_image
git reset --hard
git clean -fdx

cd ../SDL_ttf
git reset --hard
git clean -fdx