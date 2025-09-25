/**
 * @file main.cpp
 * 
 * @brief Example C++20 code file to demonstrate the usage of SDL, SDL_image, and SDL_ttf.
 */

#include <SDL.h>
#include <SDL_image.h>
#include <SDL_ttf.h>

int main(int argc, char* argv[]) {
    // Initialize SDL
    if (SDL_Init(SDL_INIT_VIDEO) != 0) {
        SDL_Log("Unable to initialize SDL: %s", SDL_GetError());
        return 1;
    }

    // Initialize SDL_image
    if (!(IMG_Init(IMG_INIT_PNG) & IMG_INIT_PNG)) {
        SDL_Log("Unable to initialize SDL_image: %s", IMG_GetError());
        SDL_Quit();
        return 1;
    }

    // Initialize SDL_ttf
    if (TTF_Init() == -1) {
        SDL_Log("Unable to initialize SDL_ttf: %s", TTF_GetError());
        IMG_Quit();
        SDL_Quit();
        return 1;
    }

    // Render a window for a few seconds
    int windowWidth = 800;
    int windowHeight = 600;
    SDL_Window* window = SDL_CreateWindow("SDL2 Example", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, windowWidth, windowHeight, SDL_WINDOW_SHOWN);
    if (!window) {
        SDL_Log("Could not create window: %s", SDL_GetError());
        TTF_Quit();
        IMG_Quit();
        SDL_Quit();
        return 1;
    }

    // Render a window for a few seconds
    SDL_Delay(3000);

    // Clean up and quit
    TTF_Quit();
    IMG_Quit();
    SDL_Quit();
    return 0;
}