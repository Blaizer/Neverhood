#include <Sprite.h>

SDL_Palette* Sprite_load_palette (Uint8* buf)
{
	SDL_Palette* palette = SDL_AllocPalette(256);
	SDL_Color* colors = palette->colors;
	int i;
	for (i = 0; i < 256; i++) {
		colors[i].r = *buf++;
		colors[i].g = *buf++;
		colors[i].b = *buf++;

		// This channel is unused in the original game (it's always 0), but we can use it.
		// Just add 1 to the alpha component of each color when packing custom sprites
		// and then mod it by 256, so that 255 alpha becomes 0
		colors[i].a = *buf++ + 255;
	}

	return palette;
}

SDL_Surface* Sprite_load_surface (SDL_Surface* surface, Uint8* source,
	Sint16 width, Sint16 height, bool rle, bool flip, bool flip_y)
{
	if (!source || !surface) return NULL;

	Uint8* dest = surface->pixels;
	int dest_pitch = surface->pitch;
	if (flip_y) {
		dest += dest_pitch * (height - 1);
		dest_pitch = -dest_pitch;
	}

	if (!rle) {
		int source_pitch = (width + 3) & ~3;
		if (!flip) {
			while (height-- > 0) {
				Copy(dest, source, source_pitch, Uint8);
				source += source_pitch;
				dest += dest_pitch;
			}
		}
		else {
			int source_skip = source_pitch - width;
			while (height-- > 0) {
				int x = width;
				while (x-- > 0)
					dest[x] = *source++;
				source += source_skip;
				dest += dest_pitch;
			}
		}
	}
	else {
		if (!flip) {
			Sint16 rows, chunks;
			goto READ_RLE;

			while (rows > 0) {
				do {
					Sint16 row_chunks = chunks;
					Sint16 skip = 0, copy = 0, prev = 0;
					while (row_chunks-- > 0) {
						skip = SDL_READ_LE16(source);
						copy = SDL_READ_LE16(source + 2);
						source += 4;

						Zero(dest + prev, skip - prev, Uint8);
						prev = skip + copy;

						Copy(dest + skip, source, copy, Uint8);
						source += copy;
					}
					Zero(dest + prev, width - prev, Uint8);

					dest += dest_pitch;
				} while (--rows > 0);

				READ_RLE:
				rows   = SDL_READ_LE16(source);
				chunks = SDL_READ_LE16(source + 2);
				source += 4;
			}
		}
		else {
			Sint16 rows, chunks;
			goto FLIP_READ_RLE;

			while (rows > 0) {
				do {
					Sint16 row_chunks = chunks;
					Sint16 skip = 0, copy = 0, prev = 0;
					while (row_chunks-- > 0) {
						skip = SDL_READ_LE16(source);
						copy = SDL_READ_LE16(source + 2);
						source += 4;

						Zero(dest + width - skip, skip - prev, Uint8);
						prev = skip + copy;

						Sint16 off = width - skip;
						Sint16 start_off = off - copy;
						while (off-- > start_off)
							dest[off] = *source++;
					}
					Zero(dest, width - prev, Uint8);

					dest += dest_pitch;
				} while (--rows > 0);

				FLIP_READ_RLE:
				rows   = SDL_READ_LE16(source);
				chunks = SDL_READ_LE16(source + 2);
				source += 4;
			}
		}
	}

	return surface;
}

void Blitter_BUILD (Blitter* self)
{
	self->surface = _app.palette_surface;
	self->src_rect = NULL;
	self->clip_rect = NULL;
	self->flip = self->flip_y = 0;
	self->repl_old = self->repl_new = 0;
}

void Blitter_DEMOLISH (Blitter* self)
{
	if (self->surface != _app.palette_surface)
		SDL_FreeSurface(self->surface);
}

void Blitter_draw_surface (Blitter* self, int x, int y, int w, int h)
{
	if (!self->surface) return;

	SDL_Rect dst;
	dst.x = x;
	dst.y = y;

	SDL_Rect* src_rect = &self->_src_rect;
	if (!self->src_rect) {
		src_rect->x = 0;
		src_rect->y = 0;
		src_rect->w = w;
		src_rect->h = h;
	}

	SDL_SetClipRect(_app.texture_surface, self->clip_rect);
	SDL_BlitSurface(self->surface, src_rect, _app.texture_surface, &dst);
}

void Blitter_do_repl (Blitter* self)
{
	if (!self->surface) return;
	Uint8 repl_old = self->repl_old;
	Uint8 repl_new = self->repl_new;
	if (repl_old == repl_new) return;

	Uint8* pixels = self->surface->pixels;
	Uint8* pixels_end = pixels + self->surface->h * self->surface->pitch;
	while (pixels < pixels_end) {
		if (*pixels == repl_old) *pixels = repl_new;
		pixels++;
	}
}

void Blitter_set_src_rect (Blitter* self, SDL_Rect* rect)
{
	if (rect) {
		self->_src_rect.x = rect->x;
		self->_src_rect.y = rect->y;
		self->_src_rect.w = rect->w;
		self->_src_rect.h = rect->h;
		self->src_rect = &self->_src_rect;
	}
	else {
		self->src_rect = NULL;
	}
}

void Blitter_set_clip_rect (Blitter* self, SDL_Rect* rect)
{
	if (rect) {
		self->_clip_rect.x = rect->x;
		self->_clip_rect.y = rect->y;
		self->_clip_rect.w = rect->w;
		self->_clip_rect.h = rect->h;
		self->clip_rect = &self->_clip_rect;
	}
	else {
		self->clip_rect = NULL;
	}
}

SpriteResource* SpriteResource_new (ArchiveEntry* entry)
{
	enum {
		SPRITE_IS_RLE         = 1,
		SPRITE_HAS_DIMENSIONS = 2,
		SPRITE_HAS_POSITION   = 4,
		SPRITE_HAS_PALETTE    = 8,
		SPRITE_HAS_IMAGE      = 16
	};

	SpriteResource* self = New(1, SpriteResource);

	if (entry->type != 2)
		error("Wrong type for resource: %08X, type: %X", entry->key, entry->type);

	self->key = entry->key;
	Uint8* buf = self->buffer = ArchiveEntry_get_buffer(entry);

	Uint16 flags = SDL_READ_LE16(buf);
	buf += 2;

	self->rle = flags & SPRITE_IS_RLE;

	if (flags & SPRITE_HAS_DIMENSIONS) {
		self->w = SDL_READ_LE16(buf);
		self->h = SDL_READ_LE16(buf + 2);
		buf += 4;
	}
	else
		self->w = self->h = 1;

	if (flags & SPRITE_HAS_POSITION) {
		self->x = SDL_READ_LE16(buf);
		self->y = SDL_READ_LE16(buf + 2);
		buf += 4;
	}
	else
		self->x = self->y = 0;

	if (flags & SPRITE_HAS_PALETTE) {
		self->palette = Sprite_load_palette(buf);
		buf += 1024;
	}
	else
		self->palette = NULL;

	if (flags & SPRITE_HAS_IMAGE) {
		self->data = buf;
	}
	else
		self->data = NULL;

	debug("sprite %08X\n%dx%d\npos(%d, %d)\npalette: %d\nrle: %d\ndata: %d\nextra flags: %d", entry->key, self->w, self->h, self->x, self->y, !!self->palette, self->rle, !!self->data, flags & ~31);

	return self;
}

SDL_Surface* SpriteResource_load_surface (SpriteResource* self, SDL_Surface* surface, bool flip, bool flip_y)
{
	return Sprite_load_surface(surface, self->data, self->w, self->h, self->rle, flip, flip_y);
}

void SpriteResource_use_palette (SpriteResource* self)
{
	App_set_palette(self->palette);
}

void SpriteResource_DESTROY (SpriteResource* self)
{
	SDL_FreePalette(self->palette);
	Free(self->buffer);
	Free(self);
}

SequenceResource* SequenceResource_new (ArchiveEntry* entry)
{
	if (entry->type != 4)
		error("Wrong type for resource: %08X, type: %X", entry->key, entry->type);

	Uint8* resource_data = ArchiveEntry_get_buffer(entry);

	Sint16 anim_list_count     = SDL_READ_LE16(resource_data);
	Sint16 anim_info_start_ofs = SDL_READ_LE16(resource_data + 2);
	Sint32 sprite_data_ofs     = SDL_READ_LE16(resource_data + 4);
	Sint32 palette_data_ofs    = SDL_READ_LE16(resource_data + 8);

	Uint8* anim_list_data = resource_data + 12;
	Sint16 anim_list_index;
	for (anim_list_index = 0; anim_list_index < anim_list_count; anim_list_index++) {
		if (SDL_READ_LE32(anim_list_data) == entry->key)
			break;
		anim_list_data += 8;
	}
	if (anim_list_index >= anim_list_count) {
		Free(resource_data);
		return NULL;
	}

	SequenceResource* self = New(1, SequenceResource);
	self->data = resource_data;
	self->key = entry->key;

	self->frame_count           = SDL_READ_LE16(anim_list_data + 4);
	Sint16 frame_list_start_ofs = SDL_READ_LE16(anim_list_data + 6);

	debug("sequence %08X\nframe count %d\nanim_list_count %d\nanim_info_start_ofs %d\nsprite_data_ofs %d\npalette_data_ofs %d\nframe_list_start_ofs %d", entry->key, self->frame_count, anim_list_count, anim_info_start_ofs, sprite_data_ofs, palette_data_ofs, frame_list_start_ofs);

	if (palette_data_ofs > 0) {
		Uint8* palette_data = resource_data + palette_data_ofs;
		self->palette = Sprite_load_palette(palette_data);
	}
	else {
		self->palette = NULL;
	}

	self->frames = New(self->frame_count, SequenceFrame);

	Uint8* sprite_data = resource_data + sprite_data_ofs;
	Uint8* frame_data = resource_data + anim_info_start_ofs + frame_list_start_ofs;
	SequenceFrame* frame = self->frames;
	SequenceFrame* last_frame = frame + self->frame_count;
	for (; frame < last_frame; frame++) {
		frame->parent = self;
		frame->frame_key          = SDL_READ_LE32(frame_data);
		frame->ticks              = SDL_READ_LE16(frame_data + 4);
		frame->offset_x           = SDL_READ_LE16(frame_data + 6);
		frame->offset_y           = SDL_READ_LE16(frame_data + 8);
		frame->w                  = SDL_READ_LE16(frame_data + 10);
		frame->h                  = SDL_READ_LE16(frame_data + 12);
		frame->delta_x            = SDL_READ_LE16(frame_data + 14);
		frame->delta_y            = SDL_READ_LE16(frame_data + 16);
		frame->collision_offset.x = (Sint16)SDL_READ_LE16(frame_data + 18);
		frame->collision_offset.y = (Sint16)SDL_READ_LE16(frame_data + 20);
		frame->collision_offset.w = (Sint16)SDL_READ_LE16(frame_data + 22);
		frame->collision_offset.h = (Sint16)SDL_READ_LE16(frame_data + 24);
		frame->unused             = SDL_READ_LE16(frame_data + 26);
		Sint32 sprite_data_offset = SDL_READ_LE32(frame_data + 28);
		frame_data += 32;

		frame->data = sprite_data + sprite_data_offset;

		// debug("frame %d\nticks %d\nx %d\ny %d\nw %d\nh %d\ndelta_x %d\ndelta_y %d\nc(%d,%d,%d,%d)\nsprite data off %d\n", (int)(frame-self->frames), frame->ticks, frame->offset_x, frame->offset_y, frame->w, frame->h, frame->delta_x, frame->delta_y, frame->collision_offset.x, frame->collision_offset.y, frame->collision_offset.w, frame->collision_offset.h, sprite_data_offset);
	}

	return self;
}

SequenceFrame* SequenceResource_frame (SequenceResource* self, int frame)
{
	if (frame < 0 || frame >= self->frame_count)
		error("Requested out-of-bounds frame: %d from sequence with frame count: %d", frame, self->frame_count);
	return self->frames + frame;
}

void SequenceResource_DESTROY (SequenceResource* self)
{
	Free(self->data);
	SDL_FreePalette(self->palette);
	Free(self->frames);
	Free(self);
}

SDL_Surface* SequenceFrame_load_surface (SequenceFrame* self, SDL_Surface* surface, bool flip, bool flip_y)
{
	return Sprite_load_surface(surface, self->data, self->w, self->h, SDL_TRUE, flip, flip_y);
}

PaletteResource* PaletteResource_new (ArchiveEntry* entry)
{
	if (entry->type != 3)
		error("Wrong type for resource: %08X, type: %X", entry->key, entry->type);

	Uint8* buffer = ArchiveEntry_get_buffer(entry);
	PaletteResource* self = Sprite_load_palette(buffer);

	return self;
}

void PaletteResource_DESTROY (PaletteResource* self)
{
	SDL_FreePalette(self);
}

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
