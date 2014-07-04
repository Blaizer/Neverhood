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

/*

MODULE=Neverhood::Sprite  PACKAGE=Neverhood::Blitter  PREFIX=Blitter_

BOOT:
	My_ISA("Neverhood::Blitter", "Neverhood::Stash");

void
Blitter_BUILD (Blitter* SELF, ...)

void
Blitter_DEMOLISH (Blitter* SELF, ...)

void
Blitter_draw_surface (Blitter* SELF, int x, int y, int w, int h)

void
Blitter_do_repl (Blitter* SELF)

bool
Blitter_flip (Blitter* SELF)
	CODE:
		RETVAL = SELF->flip;
	OUTPUT: RETVAL

bool
Blitter_flip_y (Blitter* SELF)
	CODE:
		RETVAL = SELF->flip_y;
	OUTPUT: RETVAL

void
Blitter_set_flip (Blitter* SELF, bool new)
	CODE:
		SELF->flip = new;

void
Blitter_set_flip_y (Blitter* SELF, bool new)
	CODE:
		SELF->flip_y = new;

void
Blitter_repl (Blitter* SELF)
	PPCODE:
		mXPUSHi(SELF->repl_old);
		mXPUSHi(SELF->repl_new);
		XSRETURN(2);

void
Blitter_set_repl (Blitter* SELF, Uint8 repl_old, Uint8 repl_new)
	CODE:
		SELF->repl_old = repl_old;
		SELF->repl_new = repl_new;

SDL_Surface*
Blitter_surface (Blitter* SELF)
	CODE:
		RETVAL = SELF->surface;
	OUTPUT: RETVAL

void
Blitter_set_surface (Blitter* SELF, SDL_Surface* new)
	CODE:
		SELF->surface = new;

void
Blitter_set_src_rect (Blitter* SELF, SDL_Rect* new)

void
Blitter_set_clip_rect (Blitter* SELF, SDL_Rect* new)

MODULE=Neverhood::Sprite  PACKAGE=Neverhood::SpriteResource  PREFIX=SpriteResource_

SpriteResource*
SpriteResource_new (const char* CLASS, ArchiveEntry* entry)
	C_ARGS: entry

SDL_Surface*
SpriteResource_load_surface (SpriteResource* SELF, SDL_Surface* surface, bool flip, bool flip_y)

void
SpriteResource_use_palette (SpriteResource* SELF)

void
SpriteResource_DESTROY (SpriteResource* SELF)

Sint16
SpriteResource_x (SpriteResource* SELF)
	CODE:
		RETVAL = SELF->x;
	OUTPUT: RETVAL

Sint16
SpriteResource_y (SpriteResource* SELF)
	CODE:
		RETVAL = SELF->y;
	OUTPUT: RETVAL

Sint16
SpriteResource_w (SpriteResource* SELF)
	CODE:
		RETVAL = SELF->w;
	OUTPUT: RETVAL

Sint16
SpriteResource_h (SpriteResource* SELF)
	CODE:
		RETVAL = SELF->h;
	OUTPUT: RETVAL

SDL_Palette*
SpriteResource_palette (SpriteResource* SELF)
	CODE:
		RETVAL = SELF->palette;
	OUTPUT: RETVAL

ArchiveKey
SpriteResource_key (SpriteResource* SELF)
	CODE:
		RETVAL = SELF->key;
	OUTPUT: RETVAL

MODULE=Neverhood::SequenceResource  PACKAGE=Neverhood::SequenceResource  PREFIX=SequenceResource_

SequenceResource*
SequenceResource_new (const char* CLASS, ArchiveEntry* entry)
	C_ARGS: entry

SequenceFrame*
SequenceResource_frame (SequenceResource* SELF, int frame)
		const char* CLASS = "Neverhood::SequenceFrame";

ArchiveKey
SequenceResource_key (SpriteResource* SELF)
	CODE:
		RETVAL = SELF->key;
	OUTPUT: RETVAL

void
SequenceResource_DESTROY (SequenceResource* SELF)

Sint16
SequenceResource_frame_count (SequenceResource* SELF)
	CODE:
		RETVAL = SELF->frame_count;
	OUTPUT: RETVAL

SDL_Palette*
SequenceResource_palette (SequenceResource* SELF)
	CODE:
		RETVAL = SELF->palette;
	OUTPUT: RETVAL

MODULE=Neverhood::SequenceFrame  PACKAGE=Neverhood::SequenceFrame  PREFIX=SequenceFrame_

SDL_Surface*
SequenceFrame_load_surface (SequenceFrame* SELF, SDL_Surface* surface, bool flip, bool flip_y)

Uint32
SequenceFrame_frame_key (SequenceFrame* SELF)
	CODE:
		RETVAL = SELF->frame_key;
	OUTPUT: RETVAL

Sint16
SequenceFrame_ticks (SequenceFrame* SELF)
	CODE:
		RETVAL = SELF->ticks;
	OUTPUT: RETVAL

Sint16
SequenceFrame_w (SequenceFrame* SELF)
	CODE:
		RETVAL = SELF->w;
	OUTPUT: RETVAL

Sint16
SequenceFrame_h (SequenceFrame* SELF)
	CODE:
		RETVAL = SELF->h;
	OUTPUT: RETVAL

Sint16
SequenceFrame_offset_x (SequenceFrame* SELF)
	CODE:
		RETVAL = SELF->offset_x;
	OUTPUT: RETVAL

Sint16
SequenceFrame_offset_y (SequenceFrame* SELF)
	CODE:
		RETVAL = SELF->offset_y;
	OUTPUT: RETVAL

Sint16
SequenceFrame_delta_x (SequenceFrame* SELF)
	CODE:
		RETVAL = SELF->delta_x;
	OUTPUT: RETVAL

Sint16
SequenceFrame_delta_y (SequenceFrame* SELF)
	CODE:
		RETVAL = SELF->delta_y;
	OUTPUT: RETVAL

SDL_Rect*
SequenceFrame_collision_offset (SequenceFrame* SELF)
	CODE:
		RETVAL = &SELF->collision_offset;
	OUTPUT: RETVAL

Uint16
SequenceFrame_unused (SequenceFrame* SELF)
	CODE:
		RETVAL = SELF->unused;
	OUTPUT: RETVAL

MODULE=Neverhood::Sprite  PACKAGE=Neverhood::PaletteResource  PREFIX=PaletteResource_

PaletteResource*
PaletteResource_new (CLASS, ArchiveEntry* entry)
		const char* CLASS = CLASS;
	C_ARGS: entry

void
PaletteResource_DESTROY (PaletteResource* SELF)

# */
