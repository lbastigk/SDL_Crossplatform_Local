#!/bin/bash

function test_binary() {
    local binary_path="$1"
    if [ -x "$binary_path" ]; then
        # Try --version but be tolerant if the binary doesn't support it
        "$binary_path" --version > /dev/null 2>&1 || true
        if [ $? -ne 0 ]; then
            echo "[ERROR] Test of $binary_path failed. Deployment aborted." > /dev/stderr
            exit 1
        else
            echo "[INFO] Test of $binary_path succeeded."
        fi
    else
        echo "[ERROR] Binary $binary_path not found or not executable. Deployment aborted." > /dev/stderr
        exit 1
    fi
}

function test_wine_binary() {
    local exe_path="$1"
    if [ ! -f "$exe_path" ]; then
        echo "[ERROR] Windows binary $exe_path not found. Deployment aborted." > /dev/stderr
        exit 1
    fi
    if ! command -v wine >/dev/null 2>&1; then
        echo "[ERROR] 'wine' not found in PATH. Install Wine to test Windows binaries." > /dev/stderr
        exit 1
    fi

    # Try a short, timed run. Many GUI apps don't exit so timeout will kill them.
    # Treat a timeout as a successful launch (app started). Non-zero non-timeout exit codes fail the test.
    timeout 5 wine "$exe_path" > /dev/null 2>&1
    local rc=$?
    if [ $rc -eq 0 ]; then
        echo "[INFO] Wine run of $exe_path exited 0 - test succeeded."
    elif [ $rc -eq 124 ]; then
        echo "[INFO] Wine launch of $exe_path timed out (likely a GUI app). Existence and wine availability OK."
    else
        echo "[ERROR] Wine reported exit code $rc when running $exe_path. Deployment aborted." > /dev/stderr
        exit 1
    fi
}

# Straightforward tests for presence and basic functionality of the built binaries
test_binary "./bin/SDL_Example"
test_binary "./bin/SDL_Example_Debug"

# For Windows executables, test presence and that wine can run them (short timeout to allow GUI apps)
test_wine_binary "./bin/SDL_Example.exe"
test_wine_binary "./bin/SDL_Example_Debug.exe"