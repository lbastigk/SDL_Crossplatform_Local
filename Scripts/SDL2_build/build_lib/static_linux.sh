#!/bin/bash

create_shim() {
    local name="$1"; shift
    local fallback="$1"; shift
    if ! command -v "$name" >/dev/null 2>&1 && command -v "$fallback" >/dev/null 2>&1; then
        cat > "$SHIM_DIR_IMAGE/$name" <<SHIM
#!/bin/sh
exec $fallback "\$@"
SHIM
    chmod +x "$SHIM_DIR_IMAGE/$name"
    fi
}

create_shim_ttf() {
    local name="$1"; shift
    local fallback="$1"; shift
    if ! command -v "$name" >/dev/null 2>&1 && command -v "$fallback" >/dev/null 2>&1; then
        cat > "$SHIM_DIR_TTF/$name" <<SHIM
#!/bin/sh
exec $fallback "\$@"
SHIM
        chmod +x "$SHIM_DIR_TTF/$name"
    fi
}

######################################
# Build static SDL2 library for Linux
######################################

######################################
# Arguments
# - core
# - image
# - ttf
BUILD_CORE="no"    # technically, we always have to build core first
BUILD_IMAGE="no"
BUILD_TTF="no"
for arg in "$@"; do
    case $arg in
        core)  BUILD_CORE="yes" ;;
        image) BUILD_IMAGE="yes" && BUILD_CORE="yes" ;;
        ttf)   BUILD_TTF="yes"   && BUILD_CORE="yes" ;;
        *)     echo "[ERROR] Unknown argument: $arg" > /dev/stderr; exit 1 ;;
    esac
done

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
# 1.) SDL2 Core
if [ "$BUILD_CORE" == "yes" ]; then
    echo "[INFO] Building SDL2 Core static-linux"

    # Navigate to SDL2 source directory
    cd "$PROJECT_ROOT/external/SDL2"

    # Clean and prepare
    [ -f Makefile ]  && { make clean > /dev/null 2>&1 || true; }
    [ -f configure ] || {
        # Ensure aclocal/autoconf/automake are available for autogen
        if command -v aclocal-1.16 >/dev/null 2>&1 || command -v aclocal >/dev/null 2>&1; then
            ./autogen.sh > /dev/null 2>&1 || true
        else
            echo "[ERROR] 'aclocal' not found. Install automake/autoconf (e.g. 'sudo apt install automake autoconf libtool') and re-run." > /dev/stderr
            exit 1
        fi
    }

    # Build
    ./configure --prefix="${INSTALLATION_PATH}" \
        --enable-static \
        --disable-shared CFLAGS=-fPIC
    make -j"$(nproc)" || { echo "[ERROR] SDL2 static-linux failed at make"    > /dev/stderr; exit 1; }
    make install      || { echo "[ERROR] SDL2 static-linux failed at install" > /dev/stderr; exit 1; }
fi

######################################
# 2.) SDL2_image
if [ "$BUILD_IMAGE" == "yes" ]; then
    echo "[INFO] Building SDL2_image static-linux"

    # Navigate to SDL_image source directory
    SDL_IMAGE_SRC="$PROJECT_ROOT/external/SDL_image"
    echo "[INFO] SDL2_image source dir: $SDL_IMAGE_SRC"
    if [ ! -d "$SDL_IMAGE_SRC" ]; then
        echo "[ERROR] SDL2_image source directory not found: $SDL_IMAGE_SRC" > /dev/stderr
        exit 1
    fi
    cd "$SDL_IMAGE_SRC"

    # Clean and prepare
    [ -f Makefile ]  && { make clean > /dev/null 2>&1 || true; }

    # Prepare logs and shims like shared_windows.sh to avoid automake version issues
    mkdir -p "$PROJECT_ROOT/build/logs"
    SHIM_DIR_IMAGE="$(mktemp -d)"
    cleanup_shim_image() { rm -rf "$SHIM_DIR_IMAGE"; }
    trap cleanup_shim_image EXIT

    create_shim "aclocal-1.16" "aclocal-1.17"
    create_shim "aclocal-1.16" "aclocal"
    create_shim "automake-1.16" "automake-1.17"
    create_shim "automake-1.16" "automake"

    # If no aclocal found, create empty aclocal.m4 and avoid autoreconf during make
    if ! command -v aclocal >/dev/null 2>&1 && [ ! -x "$SHIM_DIR_IMAGE/aclocal-1.16" ]; then
        echo "[WARNING] aclocal not found; creating empty aclocal.m4 and setting ACLOCAL/AUTOMAKE to ':' to avoid autoreconf during make" > /dev/stderr
        touch aclocal.m4
        export ACLOCAL=:
        export AUTOMAKE=:
    fi

    PATH="$SHIM_DIR_IMAGE:$PATH"
    export PKG_CONFIG_PATH="$INSTALLATION_PATH/lib/pkgconfig:$INSTALLATION_PATH/share/pkgconfig:$PKG_CONFIG_PATH"
    export CPPFLAGS="-I$INSTALLATION_PATH/include/SDL2 $CPPFLAGS"
    export LDFLAGS="-L$INSTALLATION_PATH/lib $LDFLAGS"
    export lt_cv_deplibs_check_method=pass_all
    export LIBS="-lSDL2 $LIBS"

    echo "[INFO] Running autoreconf -fi for SDL_image (logs -> build/logs/SDL_image_autoreconf.log)"
    autoreconf -fi > "$PROJECT_ROOT/build/logs/SDL_image_autoreconf.log" 2>&1 || {
        echo "[WARNING] autoreconf failed for SDL_image (continuing). See build/logs/SDL_image_autoreconf.log" > /dev/stderr
    }

    echo "[INFO] Running configure for SDL_image (logs -> build/logs/SDL_image_configure.log)"
    ./configure --prefix="${INSTALLATION_PATH}" \
        --with-sdl-prefix="$INSTALLATION_PATH" \
        --enable-static \
        --disable-shared CFLAGS=-fPIC \
        > "$PROJECT_ROOT/build/logs/SDL_image_configure.log" 2>&1 || {
        echo "[ERROR] configure failed for SDL_image. See build/logs/SDL_image_configure.log" > /dev/stderr
        tail -n 200 "$PROJECT_ROOT/build/logs/SDL_image_configure.log" >&2 || true
        exit 1
    }

    echo "[INFO] Running make for SDL_image (logs -> build/logs/SDL_image_make.log)"
    export ACLOCAL=:
    export AUTOMAKE=:
    make -j"$(nproc)" > "$PROJECT_ROOT/build/logs/SDL_image_make.log" 2>&1 || {
        echo "[ERROR] SDL2_image static-linux failed at make. See build/logs/SDL_image_make.log" > /dev/stderr
        tail -n 200 "$PROJECT_ROOT/build/logs/SDL_image_make.log" >&2 || true
        exit 1
    }

    echo "[INFO] Running make install for SDL_image (logs -> build/logs/SDL_image_install.log)"
    make install > "$PROJECT_ROOT/build/logs/SDL_image_install.log" 2>&1 || {
        echo "[ERROR] SDL2_image static-linux failed at install. See build/logs/SDL_image_install.log" > /dev/stderr
        tail -n 200 "$PROJECT_ROOT/build/logs/SDL_image_install.log" >&2 || true
        exit 1
    }
fi

######################################
# 3.) SDL2_ttf
if [ "$BUILD_TTF" == "yes" ]; then
    echo "[INFO] Building SDL2_ttf static-linux"

    # Navigate to SDL_ttf source directory
    SDL_TTF_SRC="$PROJECT_ROOT/external/SDL_ttf"
    echo "[INFO] SDL2_ttf source dir: $SDL_TTF_SRC"
    if [ ! -d "$SDL_TTF_SRC" ]; then
        echo "[ERROR] SDL2_ttf source directory not found: $SDL_TTF_SRC" > /dev/stderr
        exit 1
    fi
    cd "$SDL_TTF_SRC"

    # Clean and prepare
    [ -f Makefile ]  && { make clean > /dev/null 2>&1 || true; }

    # Prepare logs and shims for SDL_ttf
    mkdir -p "$PROJECT_ROOT/build/logs"
    SHIM_DIR_TTF="$(mktemp -d)"
    cleanup_shim_ttf() { rm -rf "$SHIM_DIR_TTF"; }
    trap cleanup_shim_ttf EXIT

    create_shim_ttf "aclocal-1.16" "aclocal-1.17"
    create_shim_ttf "aclocal-1.16" "aclocal"
    create_shim_ttf "automake-1.16" "automake-1.17"
    create_shim_ttf "automake-1.16" "automake"

    if ! command -v aclocal >/dev/null 2>&1 && [ ! -x "$SHIM_DIR_TTF/aclocal-1.16" ]; then
        echo "[WARNING] aclocal not found; creating empty aclocal.m4 and setting ACLOCAL/AUTOMAKE to ':' to avoid autoreconf during make" > /dev/stderr
        touch aclocal.m4
        export ACLOCAL=:
        export AUTOMAKE=:
    fi

    PATH="$SHIM_DIR_TTF:$PATH"
    export PKG_CONFIG_PATH="$INSTALLATION_PATH/lib/pkgconfig:$INSTALLATION_PATH/share/pkgconfig:$PKG_CONFIG_PATH"
    export CPPFLAGS="-I$INSTALLATION_PATH/include/SDL2 $CPPFLAGS"
    export LDFLAGS="-L$INSTALLATION_PATH/lib $LDFLAGS"
    export lt_cv_deplibs_check_method=pass_all
    export LIBS="-lSDL2 $LIBS"

    echo "[INFO] Running autoreconf -fi for SDL2_ttf (logs -> build/logs/SDL2_ttf_autoreconf.log)"
    autoreconf -fi > "$PROJECT_ROOT/build/logs/SDL2_ttf_autoreconf.log" 2>&1 || {
        echo "[WARNING] autoreconf failed for SDL2_ttf (continuing). See build/logs/SDL2_ttf_autoreconf.log" > /dev/stderr
    }

    echo "[INFO] Running configure for SDL2_ttf (logs -> build/logs/SDL2_ttf_configure.log)"
    ./configure --prefix="${INSTALLATION_PATH}" \
        --with-sdl-prefix="$INSTALLATION_PATH" \
        --enable-static \
        --disable-shared CFLAGS=-fPIC \
        > "$PROJECT_ROOT/build/logs/SDL2_ttf_configure.log" 2>&1 || {
        echo "[ERROR] configure failed for SDL2_ttf. See build/logs/SDL2_ttf_configure.log" > /dev/stderr
        tail -n 200 "$PROJECT_ROOT/build/logs/SDL2_ttf_configure.log" >&2 || true
        exit 1
    }

    echo "[INFO] Running make for SDL2_ttf (logs -> build/logs/SDL2_ttf_make.log)"
    export ACLOCAL=:
    export AUTOMAKE=:
    make -j"$(nproc)" > "$PROJECT_ROOT/build/logs/SDL2_ttf_make.log" 2>&1 || {
        echo "[ERROR] SDL2_ttf static-linux failed at make. See build/logs/SDL2_ttf_make.log" > /dev/stderr
        tail -n 200 "$PROJECT_ROOT/build/logs/SDL2_ttf_make.log" >&2 || true
        exit 1
    }

    echo "[INFO] Running make install for SDL2_ttf (logs -> build/logs/SDL2_ttf_install.log)"
    make install > "$PROJECT_ROOT/build/logs/SDL2_ttf_install.log" 2>&1 || {
        echo "[ERROR] SDL2_ttf static-linux failed at install. See build/logs/SDL2_ttf_install.log" > /dev/stderr
        tail -n 200 "$PROJECT_ROOT/build/logs/SDL2_ttf_install.log" >&2 || true
        exit 1
    }
fi

######################################
# File checks
echo "[INFO] Verifying installed files in: $INSTALLATION_PATH"

# Basic header files
if [ "$BUILD_CORE" == "yes" ]; then
    [ -f "$INSTALLATION_PATH/include/SDL2/SDL.h" ] \
    || { echo "[ERROR] SDL.h not found in $INSTALLATION_PATH/include/SDL2" > /dev/stderr; exit 1; }
fi
if [ "$BUILD_IMAGE" == "yes" ]; then
    [ -f "$INSTALLATION_PATH/include/SDL2/SDL_image.h" ] \
    || { echo "[ERROR] SDL_image.h not found in $INSTALLATION_PATH/include/SDL2" > /dev/stderr; exit 1; }
fi
if [ "$BUILD_TTF" == "yes" ]; then
    [ -f "$INSTALLATION_PATH/include/SDL2/SDL_ttf.h" ] \
    || { echo "[ERROR] SDL_ttf.h not found in $INSTALLATION_PATH/include/SDL2" > /dev/stderr; exit 1; }
fi

# Libraries
if [ "$BUILD_CORE" == "yes" ]; then
    [ -f "$INSTALLATION_PATH/lib/libSDL2.a" ] \
    || { echo "[ERROR] libSDL2.a not found in $INSTALLATION_PATH/lib" > /dev/stderr; exit 1; }
fi
if [ "$BUILD_IMAGE" == "yes" ]; then
    [ -f "$INSTALLATION_PATH/lib/libSDL2_image.a" ] \
    || { echo "[ERROR] libSDL2_image.a not found in $INSTALLATION_PATH/lib" > /dev/stderr; exit 1; }
fi
if [ "$BUILD_TTF" == "yes" ]; then
    [ -f "$INSTALLATION_PATH/lib/libSDL2_ttf.a" ] \
    || { echo "[ERROR] libSDL2_ttf.a not found in $INSTALLATION_PATH/lib" > /dev/stderr; exit 1; }
fi

######################################
# Summary
echo "[INFO] SDL2 static-linux build completed successfully!"
echo "[INFO] Libraries installed in: $INSTALLATION_PATH"
