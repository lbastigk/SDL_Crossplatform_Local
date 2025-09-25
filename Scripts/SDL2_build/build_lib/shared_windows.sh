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
# Determine project root from the script location so the script can be run from any cwd
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
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

    # List all DLL files
    echo "[INFO] Available *.dll files from project root:"
    find "$PROJECT_ROOT" -name "*.dll" -type f 2>/dev/null || echo "No DLL files found"

    exit 1
else
    echo "[SUCCESS] SDL2.dll found!"
fi

######################################
# 2.) SDL2_image
echo ""
echo "---------------------------------------------------"
echo "[INFO] Building SDL2_image shared-windows (DLLs)"

# Navigate to SDL_image source directory
cd "$PROJECT_ROOT/external/SDL_image"

# Clean and prepare
[ -f Makefile ]  && { make clean > /dev/null 2>&1 || true; }
[ -f configure ] || ./autogen.sh > ./../../build/logs/SDL_image_autogen.log 2>&1 || {
    echo "[ERROR] autogen.sh failed for SDL_image. See build/logs/SDL_image_autogen.log" > /dev/stderr
    exit 1
}

# Ensure logs dir exists
mkdir -p "$PROJECT_ROOT/build/logs"

# Check for automake/aclocal which is required to run certain Makefile targets
if ! command -v aclocal >/dev/null 2>&1 && ! command -v aclocal-1.16 >/dev/null 2>&1; then
    cat <<'MSG' > /dev/stderr
[ERROR] 'aclocal' (automake) not found. The SDL_image Makefile may try to regenerate autotools files during 'make'.
Install the required packages and re-run the script. On Debian/Ubuntu:

    sudo apt-get update && sudo apt-get install -y automake autoconf libtool pkg-config

If you prefer not to install automake system-wide, ensure that 'aclocal' or 'aclocal-1.16' is available in PATH, or run './autogen.sh' from the SDL_image directory on a machine that has automake installed and then re-run this script.
MSG
    exit 1
fi

# Export pkg-config path and flags so SDL2_image's configure can find cross-built SDL2
export PKG_CONFIG_PATH="$INSTALLATION_PATH/lib/pkgconfig:$INSTALLATION_PATH/share/pkgconfig:$PKG_CONFIG_PATH"
export CPPFLAGS="-I$INSTALLATION_PATH/include $CPPFLAGS"
export LDFLAGS="-L$INSTALLATION_PATH/lib $LDFLAGS"
export SDL2_CONFIG="$INSTALLATION_PATH/bin/sdl2-config"

# Build (capture output to logs)
echo "[INFO] Running configure for SDL_image (logs -> build/logs/SDL_image_configure.log)"
./configure --prefix="${INSTALLATION_PATH}" \
    --host=x86_64-w64-mingw32 \
    --with-sdl-prefix="$INSTALLATION_PATH" \
    --enable-sdltest=no \
    --enable-shared \
    --disable-static \
    CC=x86_64-w64-mingw32-gcc \
    CXX=x86_64-w64-mingw32-g++ \
    AR=x86_64-w64-mingw32-ar \
    RANLIB=x86_64-w64-mingw32-ranlib \
    STRIP=x86_64-w64-mingw32-strip \
    > "$PROJECT_ROOT/build/logs/SDL_image_configure.log" 2>&1 || {
    echo "[ERROR] configure failed for SDL_image. See build/logs/SDL_image_configure.log" > /dev/stderr
    tail -n 200 "$PROJECT_ROOT/build/logs/SDL_image_configure.log" >&2 || true
    exit 1
}

echo "[INFO] Running make for SDL_image (logs -> build/logs/SDL_image_make.log)"
# Workaround: if aclocal-* is missing, avoid make trying to regenerate autotools files
SHIM_DIR="$(mktemp -d)"
cleanup_shim() {
    rm -rf "$SHIM_DIR"
}
trap cleanup_shim EXIT

if ! command -v aclocal-1.16 >/dev/null 2>&1; then
    # If a different aclocal exists (e.g. aclocal-1.17 or aclocal), create a shim named aclocal-1.16
    if command -v aclocal-1.17 >/dev/null 2>&1; then
        echo "[INFO] Creating aclocal-1.16 shim that calls aclocal-1.17" > /dev/stderr
        cat > "$SHIM_DIR/aclocal-1.16" <<'SHIM'
#!/bin/sh
exec aclocal-1.17 "$@"
SHIM
        chmod +x "$SHIM_DIR/aclocal-1.16"
        PATH="$SHIM_DIR:$PATH"
    elif command -v aclocal >/dev/null 2>&1; then
        echo "[INFO] Creating aclocal-1.16 shim that calls acllocal" > /dev/stderr
        cat > "$SHIM_DIR/aclocal-1.16" <<'SHIM'
#!/bin/sh
exec aclocal "$@"
SHIM
        chmod +x "$SHIM_DIR/aclocal-1.16"
        PATH="$SHIM_DIR:$PATH"
    else
    # Also create automake-1.16 shim if needed
    if ! command -v automake-1.16 >/dev/null 2>&1; then
        if command -v automake-1.17 >/dev/null 2>&1; then
            cat > "$SHIM_DIR/automake-1.16" <<'SHIM'
#!/bin/sh
exec automake-1.17 "$@"
SHIM
            chmod +x "$SHIM_DIR/automake-1.16"
            PATH="$SHIM_DIR:$PATH"
        elif command -v automake >/dev/null 2>&1; then
            cat > "$SHIM_DIR/automake-1.16" <<'SHIM'
#!/bin/sh
exec automake "$@"
SHIM
            chmod +x "$SHIM_DIR/automake-1.16"
            PATH="$SHIM_DIR:$PATH"
        fi
    fi
        echo "[WARNING] aclocal not found; creating empty aclocal.m4 and setting ACLOCAL/AUTOMAKE to ':' to avoid autoreconf during make" > /dev/stderr
        touch aclocal.m4
        export ACLOCAL=:
        export AUTOMAKE=:
    fi
fi

export ACLOCAL=${ACLOCAL:-aclocal-1.16}
export AUTOMAKE=${AUTOMAKE:-automake}

make -j"$(nproc)" > "$PROJECT_ROOT/build/logs/SDL_image_make.log" 2>&1 || {
    echo "[ERROR] SDL_image shared-windows failed at make. See build/logs/SDL_image_make.log" > /dev/stderr
    tail -n 200 "$PROJECT_ROOT/build/logs/SDL_image_make.log" >&2 || true
    exit 1
}

echo "[INFO] Running make install for SDL_image (logs -> build/logs/SDL_image_install.log)"
make install > "$PROJECT_ROOT/build/logs/SDL_image_install.log" 2>&1 || {
    echo "[ERROR] SDL_image shared-windows failed at install. See build/logs/SDL_image_install.log" > /dev/stderr
    tail -n 200 "$PROJECT_ROOT/build/logs/SDL_image_install.log" >&2 || true
    exit 1
}

# Check if SDL2_image dll exists
if ! ls "$INSTALLATION_PATH/bin/"*image*.dll 1> /dev/null 2>&1; then
    echo "[WARNING] SDL2_image.dll not found after build!" > /dev/stderr
    
    # List all files in installation directory
    echo "[INFO] Contents of $INSTALLATION_PATH:"
    find "$INSTALLATION_PATH" -type f 2>/dev/null | head -20
    
    # List all DLL files
    echo "[INFO] Available *.dll files from project root:"
    find "$PROJECT_ROOT" -name "*.dll" -type f 2>/dev/null || echo "No DLL files found"
    
    # Check what SDL2_image actually built
    echo "[INFO] Contents of SDL2_image source after build:"
    ls -la "$PROJECT_ROOT/external/SDL2_image/.libs/" 2>/dev/null || echo "No .libs directory"
    
    exit 1
else
    echo "[SUCCESS] SDL2_image.dll found!"
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
if ! ls "$INSTALLATION_PATH/bin/"*ttf*.dll 1> /dev/null 2>&1; then
    echo "[WARNING] SDL2_ttf.dll not found after build!" > /dev/stderr
    
    # List all DLL files
    echo "[INFO] Available *.dll files from project root:"
    find "$PROJECT_ROOT" -name "*.dll" -type f 2>/dev/null || echo "No DLL files found"
    
    # Check what SDL2_ttf actually built
    echo "[INFO] Contents of SDL2_ttf source after build:"
    ls -la "$PROJECT_ROOT/external/SDL2_ttf/.libs/" 2>/dev/null || echo "No .libs directory"
    
    exit 1
else
    echo "[SUCCESS] SDL2_ttf.dll found!"
fi

######################################
# Summary
echo "[INFO] SDL2 shared-windows build completed successfully!"
echo "[INFO] Windows DLLs installed in: $INSTALLATION_PATH"
