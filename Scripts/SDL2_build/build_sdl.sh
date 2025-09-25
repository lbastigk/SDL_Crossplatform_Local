#!/bin/bash

######################################
# Parse arguments
BUILD_CORE=no
BUILD_IMAGE=no
BUILD_TTF=no
BUILD_TYPE=unknown
for arg in "$@"; do
    case $arg in
        windows)    BUILD_TYPE=windows ;;
        linux)      BUILD_TYPE=linux   ;;
        core)       BUILD_CORE=yes     ;;
        image)      BUILD_IMAGE=yes;    BUILD_CORE=yes ;;
        ttf)        BUILD_TTF=yes;      BUILD_CORE=yes ;;
        *)     echo "[ERROR] Unknown arg: $arg" >&2; exit 1 ;;
    esac
done

######################################
# Clean logs
rm -rf build/logs/*.log

######################################
# Setup directories and variables
PROJECT_ROOT="$(pwd)"
LOG_DIR="$PROJECT_ROOT/build/logs"
mkdir -p "$LOG_DIR"

if [ "$BUILD_TYPE" = windows ]; then
    INSTALLATION_PATH="$PROJECT_ROOT/build/SDL2/shared_windows"
elif [ "$BUILD_TYPE" = linux ]; then
    INSTALLATION_PATH="$PROJECT_ROOT/build/SDL2/static_linux"
else
    echo "[ERROR] BUILD_TYPE not set to 'linux' or 'windows'" >&2
    exit 1
fi

######################################
# Clean installation path
rm -rf "$INSTALLATION_PATH"
mkdir -p "$INSTALLATION_PATH"

######################################
# Helper functions : Linux static build

build_sdl2_core_linux() {
    local src="$PROJECT_ROOT/external/SDL2"
    echo "[INFO] Building SDL2 core with CMake to ${INSTALLATION_PATH}"

    cd "$src"
    rm -rf build && mkdir build && cd build

    cmake .. \
        -DCMAKE_INSTALL_PREFIX="$INSTALLATION_PATH" \
        -DCMAKE_INSTALL_LIBDIR=lib \
        -DBUILD_SHARED_LIBS=OFF \
        -DSDL_STATIC=ON \
        -DSDL_SHARED=OFF \
        -DCMAKE_INSTALL_LIBDIR=lib \
        -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
        >> "$LOG_DIR/SDL2_core_linux_cmake.configure.log" 2>&1

    make -j"$(nproc)" >> "$LOG_DIR/SDL2_core_linux_cmake.make.log" 2>&1
    make install     >> "$LOG_DIR/SDL2_core_linux_cmake.install.log" 2>&1
}

build_sdl_image_linux() {
    local src="$PROJECT_ROOT/external/SDL_image"
    echo "[INFO] Building SDL_image with CMake to ${INSTALLATION_PATH}"

    cd "$src"
    rm -rf build && mkdir build && cd build

    # Base CMake options
    cmake .. \
        -DCMAKE_INSTALL_PREFIX="$INSTALLATION_PATH" \
        -DCMAKE_INSTALL_BINDIR=bin \
        -DCMAKE_INSTALL_LIBDIR=lib \
        -DCMAKE_INSTALL_INCLUDEDIR=include \
        -DBUILD_SHARED_LIBS=OFF \
        -DCMAKE_INSTALL_LIBDIR=lib \
        -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
        >> "$LOG_DIR/SDL_image_cmake_configure.log" 2>&1

    cmake --build . -j$(nproc) >> "$LOG_DIR/SDL_image_cmake_make.log" 2>&1
    cmake --install . >> "$LOG_DIR/SDL_image_cmake_install.log" 2>&1
}

build_sdl_ttf_linux() {
    echo "[INFO] Building SDL_ttf with CMake to ${INSTALLATION_PATH}"
    cd "$PROJECT_ROOT/external/SDL_ttf"
    rm -rf build && mkdir build && cd build

    #-DFREETYPE_INCLUDE_DIRS="$INSTALLATION_PATH/deps/freetype/include/freetype2" \
    #-DZLIB_INCLUDE_DIR="/usr/include" \
    #-DSDL2_TTF_SHARED=OFF \
    #-DSDL2_TTF_STATIC=ON \
    #-DWITH_ZLIB=OFF \
    #-DSDL_ttf_BUILD_EXAMPLES=OFF \
    #-DSDL_ttf_BUILD_TESTS=OFF \
    cmake .. \
        -DCMAKE_INSTALL_PREFIX="$INSTALLATION_PATH" \
        -DBUILD_SHARED_LIBS=OFF \
        -DCMAKE_INSTALL_LIBDIR=lib \
        -DSDL2_DIR="$INSTALLATION_PATH/lib/cmake/SDL2" \
        >> "$LOG_DIR/SDL_ttf_linux_cmake.log" 2>&1

    cmake --build . -j$(nproc) >> "$LOG_DIR/SDL_ttf_linux_cmake_build.log" 2>&1
    cmake --install . >> "$LOG_DIR/SDL_ttf_linux_cmake_install.log" 2>&1
}

######################################
# Helper functions : Build FreeType and HarfBuzz for Linux static

build_freetype_linux() {
    local src="$PROJECT_ROOT/external/SDL_ttf/external/freetype"
    local install_dir="$INSTALLATION_PATH/deps/freetype"
    echo "[INFO] Building FreeType for Linux"

    cd "$src"
    rm -rf build && mkdir build && cd build

    cmake .. \
        -DCMAKE_INSTALL_PREFIX="$install_dir" \
        -DBUILD_SHARED_LIBS=OFF \
        -DCMAKE_INSTALL_LIBDIR=lib \
        -DCMAKE_POSITION_INDEPENDENT_CODE=ON
    cmake --build . -j$(nproc)
    cmake --install . --prefix "$install_dir"
}

build_harfbuzz_linux() {
    local src="$PROJECT_ROOT/external/SDL_ttf/external/harfbuzz"
    local install_dir="$INSTALLATION_PATH/deps/harfbuzz"
    echo "[INFO] Building HarfBuzz for Linux"

    cd "$src"
    rm -rf build && mkdir build && cd build

    #-DFREETYPE_INCLUDE_DIRS="$INSTALLATION_PATH/deps/freetype/include/freetype2"
    #-DFREETYPE_LIBRARY="$INSTALLATION_PATH/deps/freetype/lib/libfreetype.a" \
    cmake .. \
        -DCMAKE_INSTALL_PREFIX="$install_dir" \
        -DBUILD_SHARED_LIBS=OFF \
        -DCMAKE_INSTALL_LIBDIR=lib \
        -DCMAKE_POSITION_INDEPENDENT_CODE=ON
    cmake --build . -j$(nproc)
    cmake --install . --prefix "$install_dir"
}


######################################
# Helper functions : Windows shared build

build_sdl2_core_windows() {
    local src="$PROJECT_ROOT/external/SDL2"
    echo "[INFO] Building SDL2 core for Windows DLL"

    cd "$src"
    rm -rf build && mkdir build && cd build

    cmake .. \
        -DCMAKE_TOOLCHAIN_FILE="$PROJECT_ROOT/cmake/toolchains/dll_build.cmake" \
        -DCMAKE_INSTALL_PREFIX="$INSTALLATION_PATH" \
        -DCMAKE_INSTALL_LIBDIR=lib \
        -DBUILD_SHARED_LIBS=ON \
        -DSDL_SHARED=ON \
        -DSDL_STATIC=OFF \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_LIBDIR=lib
        >> "$LOG_DIR/SDL2_win_cmake_configure.log" 2>&1

    cmake --build . --config Release -j"$(nproc)" >> "$LOG_DIR/SDL2_win_cmake_make.log" 2>&1
    cmake --install . --config Release >> "$LOG_DIR/SDL2_win_cmake_install.log" 2>&1
}

build_sdl_image_windows(){
    echo "[INFO] Building SDL2 image for Windows DLL"
    cd "$PROJECT_ROOT"
    cd external/SDL_image
    rm -rf build && mkdir build && cd build

    cmake .. \
        -DCMAKE_TOOLCHAIN_FILE="$PROJECT_ROOT/cmake/toolchains/dll_build.cmake" \
        -DCMAKE_INSTALL_PREFIX="$INSTALLATION_PATH" \
        -DBUILD_SHARED_LIBS=ON \
        -DSDL2_IMAGE_SHARED=ON \
        -DSDL2_IMAGE_STATIC=OFF \
        -DSDL2_DIR="$INSTALLATION_PATH/lib/cmake/SDL2" \
        -DCMAKE_INSTALL_LIBDIR=lib
        >> "$LOG_DIR/SDL_image_win_cmake.log" 2>&1
    cmake --build . -j$(nproc)
    cmake --install . --prefix="$INSTALLATION_PATH"
}

build_sdl_ttf_windows(){
    echo "[INFO] Building SDL_ttf for Windows DLL"
    cd "$PROJECT_ROOT/external/SDL_ttf"
    rm -rf build && mkdir build && cd build

    # Disable host pkg-config
    export PKG_CONFIG_EXECUTABLE=""

    cmake .. \
        -DCMAKE_TOOLCHAIN_FILE="$PROJECT_ROOT/cmake/toolchains/dll_build.cmake" \
        -DCMAKE_INSTALL_PREFIX="$INSTALLATION_PATH" \
        -DFREETYPE_LIBRARY="$INSTALLATION_PATH/deps/freetype/lib/libfreetype.dll.a" \
        -DFREETYPE_INCLUDE_DIRS="$INSTALLATION_PATH/deps/freetype/include/freetype2" \
        -DHARFBUZZ_INCLUDE_DIRS="$INSTALLATION_PATH/deps/harfbuzz/include" \
        -DHARFBUZZ_LIBRARIES="$INSTALLATION_PATH/deps/harfbuzz/lib/libharfbuzz.dll.a" \
        -DBUILD_SHARED_LIBS=ON \
        -DSDL2_TTF_SHARED=ON \
        -DSDL2_TTF_STATIC=OFF \
        -DSDL2_DIR="$INSTALLATION_PATH/lib/cmake/SDL2" \
        -DSDL_ttf_BUILD_EXAMPLES=OFF \
        -DCMAKE_INSTALL_LIBDIR=lib \
        -DSDL_ttf_BUILD_TESTS=OFF \
        >> "$LOG_DIR/SDL_ttf_win_cmake.log" 2>&1
    cmake --build   . --config Release -j$(nproc) >> "$LOG_DIR/SDL_ttf_win_cmake_build.log" 2>&1
    cmake --install . --config Release >> "$LOG_DIR/SDL_ttf_win_cmake_install.log" 2>&1
}

######################################
# Helper functions : Build FreeType and HarfBuzz for Windows DLLs

build_freetype_windows() {
    echo "[INFO] Building FreeType for Windows DLL"
    cd "$PROJECT_ROOT"
    cd "external/SDL_ttf/external/freetype"
    rm -rf build && mkdir build && cd build

    cmake .. \
        -DCMAKE_TOOLCHAIN_FILE="$PROJECT_ROOT/cmake/toolchains/dll_build.cmake" \
        -DCMAKE_INSTALL_PREFIX="$INSTALLATION_PATH/deps/freetype" \
        -DBUILD_SHARED_LIBS=ON \
        -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
        >> "$LOG_DIR/freetype_win_cmake.log" 2>&1
    cmake --build . -j$(nproc)
    cmake --install . --prefix "$INSTALLATION_PATH/deps/freetype"
}

build_harfbuzz_windows() {
    echo "[INFO] Building HarfBuzz for Windows DLL"
    cd "$PROJECT_ROOT"
    cd "external/SDL_ttf/external/harfbuzz"
    rm -rf build && mkdir build && cd build

    cmake .. \
        -DCMAKE_TOOLCHAIN_FILE="$PROJECT_ROOT/cmake/toolchains/dll_build.cmake" \
        -DCMAKE_INSTALL_PREFIX="$INSTALLATION_PATH/deps/harfbuzz" \
        -DBUILD_SHARED_LIBS=ON \
        -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
        >> "$LOG_DIR/harfbuzz_win_cmake.log" 2>&1
    cmake --build . -j$(nproc)
    cmake --install . --prefix "$INSTALLATION_PATH/deps/harfbuzz"
}

######################################
# Build
if   [ "$BUILD_TYPE" = linux ]; then
    echo "[INFO] Starting SDL2 $BUILD_TYPE build at $INSTALLATION_PATH"
    [ "$BUILD_CORE"  = yes ] && build_sdl2_core_linux    #>> /dev/null 2>&1
    [ "$BUILD_IMAGE" = yes ] && build_sdl_image_linux    #>> /dev/null 2>&1
    if [ "$BUILD_TTF"   = yes ] ; then 
        build_freetype_linux    #>> /dev/null 2>&1
        build_harfbuzz_linux    #>> /dev/null 2>&1
        build_sdl_ttf_linux     #>> /dev/null 2>&1
    fi
elif [ "$BUILD_TYPE" = windows ]; then
    echo "[INFO] Starting SDL2 $BUILD_TYPE build at $INSTALLATION_PATH"
    [ "$BUILD_CORE"  = yes ] && build_sdl2_core_windows  #>> /dev/null 2>&1
    [ "$BUILD_IMAGE" = yes ] && build_sdl_image_windows  #>> /dev/null 2>&1
    if [ "$BUILD_TTF"   = yes ] ; then 
        build_freetype_windows  #>> /dev/null 2>&1
        build_harfbuzz_windows  #>> /dev/null 2>&1
        build_sdl_ttf_windows   #>> /dev/null 2>&1
    fi
else
    echo "[ERROR] Unsupported BUILD_TYPE: $BUILD_TYPE" >&2
    exit 1
fi

######################################
# File checks
echo "[INFO] Verifying installed files in: $INSTALLATION_PATH"

if   [ "$BUILD_TYPE" = linux ]; then
    # Verify installed files for Linux
    if [ "$BUILD_CORE" = yes ]; then
        [ -f "$INSTALLATION_PATH/include/SDL2/SDL.h" ] \
        || { echo "[ERROR] SDL.h missing"               >&2; exit 1; }
        [ -f "$INSTALLATION_PATH/lib/libSDL2.a" ] \
        || { echo "[ERROR] libSDL2.a missing"           >&2; exit 1; }
    fi
    if [ "$BUILD_IMAGE" = yes ]; then
        [ -f "$INSTALLATION_PATH/include/SDL2/SDL_image.h" ] \
        || { echo "[ERROR] SDL_image.h missing"         >&2; exit 1; }
        [ -f "$INSTALLATION_PATH/lib/libSDL2_image.a" ] \
        || { echo "[ERROR] libSDL2_image.a missing"     >&2; exit 1; }
    fi
    if [ "$BUILD_TTF" = yes ]; then
        [ -f "$INSTALLATION_PATH/include/SDL2/SDL_ttf.h" ] \
        || { echo "[ERROR] SDL_ttf.h missing"           >&2; exit 1; }
        [ -f "$INSTALLATION_PATH/lib/libSDL2_ttf.a" ] \
        || { echo "[ERROR] libSDL2_ttf.a missing"       >&2; exit 1; }
    fi
elif [ "$BUILD_TYPE" = windows ]; then
    # Verify installed files for Windows
    if [ "$BUILD_CORE" = yes ]; then
        [ -f "$INSTALLATION_PATH/include/SDL2/SDL.h" ] \
        || { echo "[ERROR] SDL.h missing"               >&2; exit 1; }
        [ -f "$INSTALLATION_PATH/bin/SDL2.dll" ] \
        || { echo "[ERROR] SDL2.dll missing"            >&2; exit 1; }
    fi
    if [ "$BUILD_IMAGE" = yes ]; then
        [ -f "$INSTALLATION_PATH/include/SDL2/SDL_image.h" ] \
        || { echo "[ERROR] SDL_image.h missing"         >&2; exit 1; }
        [ -f "$INSTALLATION_PATH/bin/SDL2_image.dll" ] \
        || { echo "[ERROR] SDL2_image.dll missing"      >&2; exit 1; }
    fi
    if [ "$BUILD_TTF" = yes ]; then
        [ -f "$INSTALLATION_PATH/include/SDL2/SDL_ttf.h" ] \
        || { echo "[ERROR] SDL_ttf.h missing"           >&2; exit 1; }
        [ -f "$INSTALLATION_PATH/bin/SDL2_ttf.dll" ] \
        || { echo "[ERROR] SDL2_ttf.dll missing"        >&2; exit 1; }
    fi
fi

######################################
# Summary
echo "[INFO] SDL2 static-linux build completed successfully!"
echo "[INFO] Libraries installed in: $INSTALLATION_PATH"
