#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <stdio.h>
#include <SDL/SDL.h>

typedef struct {
	Uint16 format;
	Uint16 width;
	Uint16 height;
} NHC_IMG_Image_Header;

typedef struct {
	Uint16 format;
	Uint16 u1;
	Uint32 data_offset;
	Uint32 palette_offset;
	Uint32 u2;
	Uint32 frame_count;
} NHC_IMG_Sequence_Header;

typedef struct {
	Sint16 u1;
	Sint16 u2;
	Sint16 u3;
	Sint16 u4;
	Sint16 u5;
	Sint16 width;
	Sint16 height;
	Sint16 u6;
	Sint16 u7;
	Sint16 u8;
	Sint16 u9;
	Sint16 u10;
	Sint16 u11;
	Sint16 u12;
	Uint32 data_offset;
} NHC_IMG_Frame_Header;

void NHC_IMG_Read_Palette(SDL_RWops* file, SDL_Surface* surface) {
	SDL_Color palette[256];
	SDL_RWread(file, palette, 1024, 1);
	SDL_SetPalette(surface, SDL_LOGPAL, palette, 0, 256);
}

void NHC_IMG_Read_Runs(SDL_RWops* file, SDL_Surface* surface) {
	int ypos = 0;
	Uint8* pixels = surface->pixels;

	for(;;) {
		Uint16 rows, cols;
		SDL_RWread(file, &rows, 2, 1);
		SDL_RWread(file, &cols, 2, 1);
		if(!rows && !cols) break;

		int i, j;
		for(i = 0; i < rows; i++) {
			for(j = 0; j < cols; j++) {
				Uint16 xpos, fragment_len;
				SDL_RWread(file, &xpos, 2, 1);
				SDL_RWread(file, &fragment_len, 2, 1);

				SDL_RWread(file, pixels + ypos + xpos, fragment_len, 1);
			}
			ypos += surface->pitch;
		}
	}
}

SDL_Surface* NHC_IMG_Load_Image(SDL_RWops* file) {
	NHC_IMG_Image_Header header;
	SDL_RWread(file, &header, 6, 1);

	SDL_Surface* surface = SDL_CreateRGBSurface(SDL_SWSURFACE, header.width, header.height, 8, 0, 0, 0, 0);

	if(header.format & 0x8) {
		// palette
		NHC_IMG_Read_Palette(file, surface);
	}

	if(header.format & 0x4) {
		// unknown
		SDL_RWseek(file, 4, SEEK_CUR);
	}

	SDL_LockSurface(surface);
	if(header.format & 0x1) {
		// compressed
		NHC_IMG_Read_Runs(file, surface);
	}
	else {
		// uncompressed
		Uint8* pixels = surface->pixels;
		int surface_len = header.height * surface->pitch;
		int ypos;
		for(ypos = 0; ypos < surface_len; ypos += surface->pitch) {
			SDL_RWread(file, pixels + ypos, header.width, 1);
		}
	}
	SDL_UnlockSurface(surface);

	return surface;
}

SDL_Surface* NHC_IMG_Load_Sequence(SDL_RWops* file, int frame) {
	NHC_IMG_Sequence_Header header;
	SDL_RWread(file, &header, 20, 1);

	if(header.format == 2) {
		// unknown
		SDL_RWseek(file, 8, SEEK_CUR);
	}

	NHC_IMG_Frame_Header frame_header;
	if(frame) SDL_RWseek(file, frame * 32, SEEK_CUR);
	SDL_RWread(file, &frame_header, 32, 1);

	SDL_Surface* surface = SDL_CreateRGBSurface(SDL_SWSURFACE, frame_header.width, frame_header.height, 8, 0, 0, 0, 0);

	SDL_RWseek(file, header.palette_offset, SEEK_SET);
	NHC_IMG_Read_Palette(file, surface);

	SDL_RWseek(file, header.data_offset + frame_header.data_offset, SEEK_SET);
	SDL_LockSurface(surface);
	NHC_IMG_Read_Runs(file, surface);
	SDL_UnlockSurface(surface);

	return surface;
}

SDL_Surface* NHC_IMG_Load(const char* filename, int type, int frame) {
	SDL_RWops* file = SDL_RWFromFile(filename, "rb");

	SDL_Surface* surface;
	if(type == 2) {
		surface = NHC_IMG_Load_Image(file);
	}
	else if(type == 4) {
		surface = NHC_IMG_Load_Sequence(file, frame);
	}
	else { /* error */ }

	SDL_RWclose(file);
	SDL_FreeRW(file);
	return surface;
}

void NHC_IMG_Mirror(SDL_Surface* surface) {
	int surface_len = surface->h * surface->pitch;
	Uint8* pixels = surface->pixels;
	Uint8* pixels_copy = malloc(surface_len);
	memcpy(pixels_copy, pixels, surface_len);

	int ypos, xpos;
	for(ypos = 0; ypos < surface_len; ypos += surface->pitch) {
		for(xpos = 0; xpos < surface->w; xpos++) {
			pixels[ypos + xpos] = pixels_copy[ypos + surface->w - xpos - 1];
		}
	}
	
	free(pixels_copy);
}

MODULE = Games::Neverhood::Image		PACKAGE = Games::Neverhood::Image		PREFIX = Neverhood_Image_

SDL_Surface*
Neverhood_Image_load(filename, type, frame)
		char* filename
		int type
		int frame
	PREINIT:
		char* CLASS = "SDL::Surface";
	CODE:
		RETVAL = NHC_IMG_Load(filename, type, frame);
	OUTPUT:
		RETVAL

void
Neverhood_Image_mirror(surface)
		SDL_Surface* surface
	CODE:
		NHC_IMG_Mirror(surface);
