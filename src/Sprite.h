// Sprite - decode some things that get drawn to the game surface
//
// Based on the ScummVM Neverhood Engine's sprite resource code

#pragma once
#include <helper.h>
#include <Archive.h>
#include <App.h>
#include <Stash.h>

SDL_Palette* Sprite_load_palette (Uint8* buf);
SDL_Surface* Sprite_load_surface (SDL_Surface* surface, Uint8* source,
	Sint16 width, Sint16 height, bool rle, bool flip, bool flip_y);

typedef struct {
	SV* stash; // so that we can extend this class
	SDL_Surface* surface;
	SDL_Rect* src_rect, _src_rect;
	SDL_Rect* clip_rect, _clip_rect;
	bool flip, flip_y;
	Uint8 repl_old, repl_new;
} Blitter;

void Blitter_BUILD (Blitter*);
void Blitter_DEMOLISH (Blitter*);
void Blitter_draw_surface (Blitter* self, int x, int y, int w, int h);
void Blitter_do_repl (Blitter*);
void Blitter_set_src_rect (Blitter* self, SDL_Rect* rect);
void Blitter_set_clip_rect (Blitter* self, SDL_Rect* rect);

typedef struct {
	Uint8* buffer;
	Uint8* data;
	SDL_Palette* palette;
	Sint16 w, h;
	Sint16 x, y;
	bool rle;
	Uint32 key;
} SpriteResource;

SpriteResource* SpriteResource_new (ArchiveEntry* entry);
SDL_Surface* SpriteResource_load_surface (SpriteResource*, SDL_Surface* surface, bool flip, bool flip_y);
void SpriteResource_use_palette (SpriteResource*);
void SpriteResource_DESTROY (SpriteResource*);

typedef struct SequenceResource {
	struct SequenceFrame* frames;
	SDL_Palette* palette;
	Uint8* data;
	Sint16 frame_count;
	Uint32 key;
} SequenceResource;

typedef struct SequenceFrame {
	Uint8* data;
	struct SequenceResource* parent;
	Uint32 frame_key;
	Sint16 ticks;
	Sint16 w, h;
	Sint16 offset_x, offset_y;
	Sint16 delta_x, delta_y;
	SDL_Rect collision_offset;
	Uint16 unused;
} SequenceFrame;

SequenceResource* SequenceResource_new (ArchiveEntry* entry);
SequenceFrame* SequenceResource_frame (SequenceResource*, int frame);
void SequenceResource_DESTROY (SequenceResource*);
SDL_Surface* SequenceFrame_load_surface (SequenceFrame* self, SDL_Surface* surface, bool flip, bool flip_y);

typedef SDL_Palette PaletteResource;

PaletteResource* PaletteResource_new (ArchiveEntry* entry);
void PaletteResource_DESTROY (PaletteResource*);
