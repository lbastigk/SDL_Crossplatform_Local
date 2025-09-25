############################################################
# SDL_Example Build Configuration
#
# Platform Notes:
# - On Linux, static SDL libraries are linked for portability.
# - On Windows (cross-compiled from Linux), prebuilt SDL DLL import libraries are linked.
#
# For more details, see README.md.
############################################################

############################################################
# General
cmake_minimum_required(VERSION 3.16)
project(SDL_Example)

# Define global compile definitions (prefer modern CMake)
add_compile_definitions(SDL_DISABLE_IMPLEMENTS)

# Set C++ standard
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Only add debug info in Debug builds
if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    add_compile_options(-g)
endif()

# Setting output inside ./build/<build-type>, 
# moving to proper location+renaming later on in the build.sh script
# CMAKE_BINARY_DIR is set by build.sh
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR})

# Echo the start of the configuration
message(STATUS "Starting configuration for project SDL_Example")

############################################################
# Shortcut paths to external dependencies
set(SDL2_BUILD_PATH     "${CMAKE_SOURCE_DIR}/build/SDL2")

############################################################
# Source files - Automatically include all .cpp files in src/
file(GLOB_RECURSE COMMON_SOURCES 
    "${CMAKE_SOURCE_DIR}/src/*.cpp"
)

############################################################
# Define executable
add_executable(SDL_Example
    ${CMAKE_SOURCE_DIR}/src/main.cpp
    ${COMMON_SOURCES}
)

############################################################
# General include directories
target_include_directories(SDL_Example
    PRIVATE
        ${CMAKE_SOURCE_DIR}/include
)

############################################################
# Link externallibraries
target_link_libraries(SDL_Example)

############################################################
# Compile options: Warnings
set_source_files_properties(
  ./src/ 
  "-w"
)

############################################################
# Platform-Specific

##################
# WINDOWS        #
##################
if(WIN32)
    message(STATUS "Targeting Windows")

    # Include SDL Libraries
    target_include_directories(SDL_Example PRIVATE
        ${SDL2_BUILD_PATH}/shared_windows/include/SDL2
    )

    # Force console window in Debug, GUI (no console) in Release
    if(CMAKE_BUILD_TYPE STREQUAL "Debug")
        target_link_options(SDL_Example PRIVATE -mconsole)
    else()
        # Later on, for actual release:
        #target_link_options(SDL_Example PRIVATE -mwindows)

        # For now, for console output in release version:
        target_link_options(SDL_Example PRIVATE -mconsole)
    endif()

    # Link libraries
    target_link_libraries(SDL_Example PRIVATE
        -lmingw32
        "${SDL2_BUILD_PATH}/shared_windows/lib/libSDL2main.a"
        "${SDL2_BUILD_PATH}/shared_windows/lib/libSDL2_ttf.dll.a"
        "${SDL2_BUILD_PATH}/shared_windows/lib/libSDL2_image.dll.a"
        "${SDL2_BUILD_PATH}/shared_windows/lib/libSDL2.dll.a"
        -lsetupapi
        -limm32
        -lversion
        -loleaut32
        -lole32
        -luuid
        -lwinmm
        -lws2_32
    )
##################
# LINUX          #
##################
elseif(UNIX)
    message(STATUS "Targeting Linux")

    target_include_directories(SDL_Example PRIVATE
        ${SDL2_BUILD_PATH}/static_linux/include/SDL2
    )

    # Link known libraries directly (simpler and deterministic)
    target_link_libraries(SDL_Example PRIVATE
        "${SDL2_BUILD_PATH}/static_linux/lib/libSDL2main.a"
        "${SDL2_BUILD_PATH}/static_linux/lib/libSDL2_ttf.a"
        "${SDL2_BUILD_PATH}/static_linux/lib/libSDL2_image.a"
        "${SDL2_BUILD_PATH}/static_linux/lib/libSDL2.a"
        "${SDL2_BUILD_PATH}/static_linux/deps/freetype/lib/libfreetype.a"
        "${SDL2_BUILD_PATH}/static_linux/deps/harfbuzz/lib/libharfbuzz.a"
        # libfreetype depends on zlib, libpng, bzip2 and brotli
        z
        png
        bz2
        brotlidec
        m
    )
##################
# UNKNOWN        #
##################
else()
    message(STATUS "Targeting unknown platform... exiting.")

    # exit
    exit(1)
endif()

