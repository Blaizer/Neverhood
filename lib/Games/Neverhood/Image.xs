#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <stdio.h>
#include "SDL.h"

typedef struct {
	Uint16 format;
	Uint16 width;
	Uint16 height;
} NHC_IMG_Header;

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

typedef struct {
	Uint16 rows;
	Uint16 cols;
} NHC_IMG_Run_Header;

typedef struct {
	Uint16 xpos;
	Uint16 fragment_len;
} NHC_IMG_Run_Data;

void NHC_IMG_Read_Palette(SDL_RWops *src, SDL_Surface *surface) {
	SDL_Color palette[256];
	SDL_RWread(src, palette, 1024, 1);
	SDL_SetPalette(surface, SDL_LOGPAL, palette, 0, 256);
}

void NHC_IMG_Read_Runs(SDL_RWops *src, SDL_Surface *surface, int width) {
	int ypos = 0;
	Uint8 *pixels = (Uint8 *)surface->pixels;
	
	while(1) {
		NHC_IMG_Run_Header run_header;
		SDL_RWread(src, &run_header, 4, 1);
		if(!run_header.rows && !run_header.cols) break;

		int i, j;
		for(i = 0; i < run_header.rows; i++) {
			for(j = 0; j < run_header.cols; j++) {
				NHC_IMG_Run_Data run_data;
				SDL_RWread(src, &run_data, 4, 1);
				SDL_RWread(src, &pixels[ypos + run_data.xpos], run_data.fragment_len, 1);
			}
			ypos += width;
		}
	}
}

SDL_Surface* NHC_IMG_Load(const char* filename, int mirror) {
	SDL_RWops *src = SDL_RWFromFile(filename, "rb");
	
	NHC_IMG_Header header;
	SDL_RWread(src, &header, 6, 1);

	SDL_Surface* surface = SDL_CreateRGBSurface(SDL_SWSURFACE, header.width, header.height, 8, 0, 0, 0, 0);
	
	if(header.format & 0x8) {
		// palette
		NHC_IMG_Read_Palette(src, surface);
	}
	
	if(header.format & 0x4) {
		// unknown
		SDL_RWseek(src, 4, SEEK_CUR);
	}
	
	if(header.format & 0x1) {
		// compressed
		NHC_IMG_Read_Runs(src, surface, header.width);
	}
	else {
		// uncompressed
		SDL_RWread(src, surface->pixels, header.width * header.height, 1);
	}
	
	SDL_RWclose(src);
	return surface;
}

SDL_Surface* NHC_IMG_Load_Sequence(const char* filename, int frame, int mirror) {
	SDL_RWops *src = SDL_RWFromFile(filename, "rb");

	NHC_IMG_Sequence_Header header;
	SDL_RWread(src, &header, 20, 1);
	
	if(header.format == 2) {
		// unknown
		SDL_RWseek(src, 8, SEEK_CUR);
	}
	
	NHC_IMG_Frame_Header frame_header;
	if(frame) SDL_RWseek(src, frame * 32, SEEK_CUR);
	SDL_RWread(src, &frame_header, 32, 1);

	SDL_Surface* surface = SDL_CreateRGBSurface(SDL_SWSURFACE, frame_header.width, frame_header.height, 8, 0, 0, 0, 0);
	
	SDL_RWseek(src, header.palette_offset, SEEK_SET);
	NHC_IMG_Read_Palette(src, surface);

	SDL_RWseek(src, header.data_offset + frame_header.data_offset, SEEK_SET);
	NHC_IMG_Read_Runs(src, surface, frame_header.width);
	
	SDL_RWclose(src);
	return surface;
}

MODULE = Games::Neverhood::Image		PACKAGE = Games::Neverhood::Image		PREFIX = Neverhood_Image_

SDL_Surface*
Neverhood_Image_load(filename, mirror)
		char* filename
		int mirror
	PREINIT:
		char* CLASS = "SDL::Surface";
	CODE:
		RETVAL = NHC_IMG_Load(filename, mirror);
	OUTPUT:
		RETVAL

SDL_Surface*
Neverhood_Image_load_sequence(filename, frame, mirror)
		char* filename
		int frame
		int mirror
	PREINIT:
		char* CLASS = "SDL::Surface";
	CODE:
		RETVAL = NHC_IMG_Load_Sequence(filename, frame, mirror);
	OUTPUT:
		RETVAL
