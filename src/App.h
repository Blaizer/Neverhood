// App - Perl interface to SDL

#pragma once
#include <helper.h>
#include <Audio.h>

typedef struct {
	SV* stash;
	SDL_Window* window;
	SDL_Renderer* renderer;
	SDL_Texture* texture;

	SDL_Surface* texture_surface;
	SDL_Rect texture_surface_rect;

	SDL_Surface* palette_surface;
	SDL_Palette* palette;

	// scenes that want to draw to the entire screen can use these
	int window_w, window_h;

	bool stop;
	bool restart;
	bool pause;
	bool first;
	double frame_ticks;

	struct {
		SV* draw;
		SV* render;
		SV* first;
		SV* next;
		SV* on_space;
		SV* on_escape;
	} method;

	HV* options;
} App;

extern App _app;

void App_set_palette (SDL_Palette* palette);
void App_set_palette_colors (SDL_Palette* palette, int i, int n);
SV* App_get_option (const char* name);
IV App_get_option_IV (const char* name);
char* App_get_option_PV (const char* name);
void App_set_texture_surface_rect (int x, int y, int w, int h);
void App_set_vsync (bool vsync);
void App_render_texture_surface ();
