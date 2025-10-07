# SDL Crossplatform Local Build — Made easy

A Repository to build SDL2, SDL2_image and SDL2_ttf locally (static Linux libs and Windows DLLs).

Tested on:

- Fedora 42
- Kubuntu 25.04 (TODO: SDL_ttf might fail, missing dependency in package installation script!)

Quick start
-----------

1. Clone and cd into the repo.
2. Run (as a normal user):

```bash
Scripts/install.sh
```

Or run a focused build (keeps console output):

```bash
# builds core, image and ttf for linux
Scripts/build_sdl.sh linux core image ttf

# builds core, image and ttf for windows
Scripts/build_sdl.sh windows core image ttf 
```

Full worflow with SDL installation, application build and test:
```bash
Scripts/install.sh && Scripts/build.sh && Scripts/test_binaries.sh
```

Outputs & logs
--------------

- Linux static: `build/SDL2/static_linux`
- Windows shared: `build/SDL2/shared_windows`
- Logs: `build/logs/*.log`

Prerequisites
-------------

- CMake, build tools and a C compiler. The helper script attempts to install packages via `apt` or `dnf` (see `Scripts/package_installation.sh`).
- For Windows DLL builds: a mingw-w64 toolchain and the provided toolchain file `cmake/toolchains/dll_build.cmake` for dlls and `cmake/toolchains/application_build.cmake` for the SDL application itself

Important notes
---------------

- `install.sh` removes `external/` and `build/` before building. Back up local changes.
- Package installation supports only `apt` and `dnf` and the package list may be broader than needed.
- Check `build/logs/` for full CMake/make logs (the top-level script hides console output).


Issues or improvements: open an issue or PR.
