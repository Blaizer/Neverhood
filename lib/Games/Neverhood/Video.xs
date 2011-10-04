#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <stdio.h>
#include <SDL/SDL.h>

#define BUFFER_LEN 1024

typedef struct {
	SDL_RWops* file;
	int byte_offset;
	int bit_offset;
	Uint8 buffer[BUFFER_LEN];
} NHC_BS;

NHC_BS* NHC_BS_new(SDL_RWops* file) {
	NHC_BS* bs;
	bs->file = file;
	bs->byte_offset = 0;
	bs->bit_offset = 0;
	return bs;
}

int NHC_BS_read(NHC_BS* bs, int bits) {
	return SDL_RWread(bs->file, bs->buffer, ceil(((float)(bits + bs->bit_offset)) / 8), 1);
}

int NHC_BS_seek(NHC_BS* bs, int bits) {
	int ret = SDL_RWseek(bs->file, (int)(bits / 8), SEEK_SET);
	bs->byte_offset = 0;
	bs->bit_offset = bits % 8;
	return ret;
}

int NHC_BS_tell(NHC_BS* bs) {
	return SDL_RWtell(bs->file) * 8 + bs->bit_offset;
}

Uint8 NHC_BS_next_1(NHC_BS* bs) {
	Uint8 ret = (bs->buffer)[bs->byte_offset] >> bs->bit_offset & 1;
	if(++bs->bit_offset >= 8) {
		bs->bit_offset = 0;
		bs->byte_offset++;
	}
	return ret;
}

Uint8 NHC_BS_next_8(NHC_BS* bs) {
	if(bs->bit_offset) {
		return
			(bs->buffer)[bs->byte_offset] >> bs->bit_offset
			| (bs->buffer)[++bs->byte_offset] << 8 - bs->bit_offset & 0xFF
		;
	}
	return (bs->buffer)[bs->byte_offset++];
}

Uint16 NHC_BS_next_16(NHC_BS* bs) {
	if(bs->bit_offset) {
		return
			(Uint16)((bs->buffer)[bs->byte_offset] >> bs->bit_offset
			| (bs->buffer)[++bs->byte_offset] << 8 - bs->bit_offset & 0xFF)
			| (Uint16)((bs->buffer)[++bs->byte_offset]) << 16 - bs->bit_offset & 0xFFFF;
		;
	}
	return
		(Uint16)((bs->buffer)[bs->byte_offset])
		| (Uint16)((bs->buffer)[++bs->byte_offset])
	;
}

typedef struct {
	Uint32 signature;
	Uint32 width;
	Uint32 height;
	Uint32 frames;
	Uint32 frame_rate;
	Uint32 flags;
	Uint32 audio_size[7];
	Uint32 trees_size;
	Uint32 mmap_size;
	Uint32 mclr_size;
	Uint32 full_size;
	Uint32 type_size;
	Uint32 audio_rate[7];
	Uint32 unused;
} NHC_VID_Header;

typedef struct {
	Uint8* mmap;
    Uint8* mclr;
    Uint8* full;
    Uint8* type;
} NHC_VID_Huffman_Trees;

typedef struct {
	NHC_BS* bs;
	NHC_VID_Header* header;
	Uint32* frame_sizes;
	Uint8* frame_types;
	NHC_VID_Huffman_Trees* huffman_trees;
	Uint8* frames_data;
} NHC_VID;

// typedef struct {

// } NHC_VID_Huffman_Tree;

NHC_VID* NHC_VID_new(const char* filename) {
	NHC_VID* vid;
	// SDL_RWops* file = SDL_RWFromFile(filename, "rb");
	// SDL_RWread(file, vid->header, 104, 1);

	// vid->frame_sizes = malloc(vid->header->frames * 4);
	// SDL_RWread(file, vid->frame_sizes, vid->header->frames * 4, 1);

	// vid->frame_types = malloc(vid->header->frames);
	// SDL_RWread(file, vid->frame_types, vid->header->frames, 1);

	// vid->bs = NHC_BS_new(file);
	
	// vid->huffman_trees->mmap = NHC_VID_Huffman_Tree_new(vid->bs, vid->header->mmap_size);
	// vid->huffman_trees->mclr = NHC_VID_Huffman_Tree_new(vid->bs, vid->header->mclr_size);
	// vid->huffman_trees->full = NHC_VID_Huffman_Tree_new(vid->bs, vid->header->full_size);
	// vid->huffman_trees->type = NHC_VID_Huffman_Tree_new(vid->bs, vid->header->type_size);
	
	return vid;
}

MODULE = Games::Neverhood::Video		PACKAGE = Games::Neverhood::Video		PREFIX = Neverhood_Video_

NHC_VID*
Neverhood_Video_new(CLASS, filename)
		char* CLASS
		const char* filename
	CODE:
		RETVAL = NHC_VID_new(filename);
	OUTPUT:
		RETVAL

char*
Neverhood_Video_name(vid)
		NHC_VID* vid
	CODE:
		RETVAL = "video";
	OUTPUT:
		RETVAL