#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <stdio.h>
#include <SDL/SDL.h>

#define BUFFER_LEN 1048576

typedef struct {
	SDL_RWops* file;
	int byte_offset;
	int bit_offset;
	Uint8 buffer[BUFFER_LEN];
} NHC_BS;

NHC_BS* NHC_BS_new(SDL_RWops* file) {
	NHC_BS *bs = malloc(sizeof(NHC_BS));
	bs->file = file;
	bs->byte_offset = 0;
	bs->bit_offset = 0;
	return bs;
}

int NHC_BS_read(NHC_BS* bs, int bytes) {
	return SDL_RWread(bs->file, bs->buffer, bytes, 1);
}

int NHC_BS_seek(NHC_BS* bs, int bytes) {
	bs->byte_offset = 0;
	bs->bit_offset = 0;
	return SDL_RWseek(bs->file, bytes, SEEK_SET);
}

int NHC_BS_offset(NHC_BS* bs, int bytes) {
	bs->byte_offset = bytes;

}

int NHC_BS_tell(NHC_BS* bs) {
	return SDL_RWtell(bs->file);
}

Uint8 NHC_BS_get_1(NHC_BS* bs) {
	Uint8 ret = bs->buffer[bs->byte_offset] >> bs->bit_offset & 1;
	if(++bs->bit_offset >= 8) {
		bs->bit_offset = 0;
		bs->byte_offset++;
	}
	return ret;
}

Uint8 NHC_BS_get_8(NHC_BS* bs) {
	if(bs->bit_offset) {
		return
			bs->buffer[bs->byte_offset] >> bs->bit_offset |
			bs->buffer[++bs->byte_offset] << 8 - bs->bit_offset & 0xFF
		;
	}
	return bs->buffer[bs->byte_offset++];
}

Uint16 NHC_BS_get_16(NHC_BS* bs) {
	if(bs->bit_offset) {
		return
			bs->buffer[bs->byte_offset] >> bs->bit_offset |
			bs->buffer[++bs->byte_offset] |
			bs->buffer[++bs->byte_offset] << 16 - bs->bit_offset & 0xFFFF;
		;
	}
	return
		(Uint16)bs->buffer[bs->byte_offset++] |
		(Uint16)bs->buffer[++bs->byte_offset] << 8
	;
}

#define NHC_VID_READ_FRAMES 5

const Uint8 palmap[64] = {
	0x00, 0x04, 0x08, 0x0C, 0x10, 0x14, 0x18, 0x1C,
	0x20, 0x24, 0x28, 0x2C, 0x30, 0x34, 0x38, 0x3C,
	0x41, 0x45, 0x49, 0x4D, 0x51, 0x55, 0x59, 0x5D,
	0x61, 0x65, 0x69, 0x6D, 0x71, 0x75, 0x79, 0x7D,
	0x82, 0x86, 0x8A, 0x8E, 0x92, 0x96, 0x9A, 0x9E,
	0xA2, 0xA6, 0xAA, 0xAE, 0xB2, 0xB6, 0xBA, 0xBE,
	0xC3, 0xC7, 0xCB, 0xCF, 0xD3, 0xD7, 0xDB, 0xDF,
	0xE3, 0xE7, 0xEB, 0xEF, 0xF3, 0xF7, 0xFB, 0xFF
};

const int block_runs[64] = {
	1,    2,    3,    4,    5,    6,    7,    8,
	9,    10,   11,   12,   13,   14,   15,   16,
	17,   18,   19,   20,   21,   22,   23,   24,
	25,   26,   27,   28,   29,   30,   31,   32,
	33,   34,   35,   36,   37,   38,   39,   40,
	41,   42,   43,   44,   45,   46,   47,   48,
	49,   50,   51,   52,   53,   54,   55,   56,
	57,   58,   59,   128,  256,  512,  1024, 2048
};

enum SmkBlockTypes {
	SMK_BLK_MONO = 0,
	SMK_BLK_FULL = 1,
	SMK_BLK_SKIP = 2,
	SMK_BLK_FILL = 3
};

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

// recursive type definition
typedef struct NHC_VID_Node {
	union {
		struct NHC_VID_Node* branch[2];
		Uint16 leaf;
	};
	int is_leaf;
} NHC_VID_Node;

typedef struct {
	NHC_VID_Node* node;
	Uint16 marker_1;
	Uint16 marker_2;
	Uint16 marker_3;
	NHC_VID_Node* marker_1_node;
	NHC_VID_Node* marker_2_node;
	NHC_VID_Node* marker_3_node;
} NHC_VID_Tree;

typedef struct {
	NHC_BS* bs;
	NHC_VID_Header* header;
	Uint32* frame_sizes;
	Uint8* frame_types;
	NHC_VID_Tree* mmap_tree;
    NHC_VID_Tree* mclr_tree;
    NHC_VID_Tree* full_tree;
    NHC_VID_Tree* type_tree;
	SV* hash;
	SDL_Surface* surface;
	int frame;
	int last_read_frame;
} NHC_VID;

NHC_VID_Node* NHC_VID_Byte_Tree_Recurse(NHC_BS* bs, NHC_VID_Node* node) {
	if(NHC_BS_get_1(bs)) {
		NHC_VID_Node* left = malloc(sizeof(NHC_VID_Node));
		NHC_VID_Byte_Tree_Recurse(bs, left);
		if (node == NULL) {
			return left;
		}
		else {
			node->branch[0] = left;
		}
		node->branch[1] = malloc(sizeof(NHC_VID_Node));
		NHC_VID_Byte_Tree_Recurse(bs, node->branch[1]);

		return;
	}
	node->leaf = NHC_BS_get_8(bs);
	node->is_leaf = 1;
}

NHC_VID_Node* NHC_VID_Byte_Tree_New(NHC_BS* bs) {
	if(!NHC_BS_get_1(bs)) return NULL;

	NHC_VID_Node* tree = NHC_VID_Byte_Tree_Recurse(bs, NULL);

	NHC_BS_get_1(bs);

	return tree;
}

Uint16 NHC_VID_Byte_Tree_Decode(NHC_BS* bs, NHC_VID_Node* node) {
	if(node == NULL) return 0;
	while(!node->is_leaf) {
		node = node->branch[NHC_BS_get_1(bs)];
	}
	return node->leaf;
}

NHC_VID_Node* NHC_VID_Tree_Recurse(NHC_BS* bs, NHC_VID_Tree* tree, NHC_VID_Node* low_byte_tree, NHC_VID_Node* high_byte_tree, NHC_VID_Node* node) {
	if(NHC_BS_get_1(bs)) {
		NHC_VID_Node* left = malloc(sizeof(NHC_VID_Node));
		NHC_VID_Tree_Recurse(bs, tree, low_byte_tree, high_byte_tree, left);
		if(node == NULL) {
			return left;
		}
		else {
			node->branch[0] = left;
		}
		node->branch[1] = malloc(sizeof(NHC_VID_Node));
		NHC_VID_Tree_Recurse(bs, tree, low_byte_tree, high_byte_tree, node->branch[1]);

		return;
	}
	Uint16 leaf =
		NHC_VID_Byte_Tree_Decode(bs, low_byte_tree) |
		NHC_VID_Byte_Tree_Decode(bs, high_byte_tree) << 8
	;
	if(leaf == tree->marker_1) {
		tree->marker_1_node = node;
		leaf = 0;
	}
	else if(leaf == tree->marker_2) {
		tree->marker_2_node = node;
		leaf = 0;
	}
	else if(leaf == tree->marker_3) {
		tree->marker_3_node = node;
		leaf = 0;
	}
	node->leaf = leaf;
	node->is_leaf = 1;
}

NHC_VID_Tree* NHC_VID_Tree_New(NHC_BS* bs) {
	if(!NHC_BS_get_1(bs)) return NULL;

	NHC_VID_Tree* tree = malloc(sizeof(NHC_VID_Tree));

	NHC_VID_Node* low_byte_tree = NHC_VID_Byte_Tree_New(bs);
	NHC_VID_Node* high_byte_tree = NHC_VID_Byte_Tree_New(bs);

	tree->marker_1 = NHC_BS_get_16(bs);
	tree->marker_2 = NHC_BS_get_16(bs);
	tree->marker_3 = NHC_BS_get_16(bs);

	tree->node = NHC_VID_Tree_Recurse(bs, tree, low_byte_tree, high_byte_tree, NULL);

	NHC_BS_get_1(bs);

	if(tree->marker_1_node == NULL) tree->marker_1_node = malloc(sizeof(NHC_VID_Node));
	if(tree->marker_2_node == NULL) tree->marker_2_node = malloc(sizeof(NHC_VID_Node));
	if(tree->marker_3_node == NULL) tree->marker_3_node = malloc(sizeof(NHC_VID_Node));

	return tree;
}

Uint16 NHC_VID_Tree_Decode(NHC_BS* bs, NHC_VID_Tree* tree) {
	NHC_VID_Node* node = tree->node;
	if(node == NULL) return 0;
	while(!node->is_leaf) {
		node = node->branch[NHC_BS_get_1(bs)];
	}
	Uint16 leaf = node->leaf;
	if(leaf != tree->marker_1) {
		tree->marker_3 = tree->marker_2;
		tree->marker_2 = tree->marker_1;
		tree->marker_1 = leaf;

		tree->marker_3_node->leaf = tree->marker_2_node->leaf;
		tree->marker_2_node->leaf = tree->marker_1_node->leaf;
		tree->marker_1_node->leaf = leaf;
	}
	return leaf;
}

NHC_VID* NHC_VID_new(const char* filename) {
	NHC_VID* vid = malloc(sizeof(NHC_VID));
	SDL_RWops* file = SDL_RWFromFile(filename, "rb");

	vid->header = malloc(104);
	SDL_RWread(file, vid->header, 104, 1);

	vid->frame_sizes = malloc(vid->header->frames * 4);
	SDL_RWread(file, vid->frame_sizes, vid->header->frames * 4, 1);

	vid->frame_types = malloc(vid->header->frames);
	SDL_RWread(file, vid->frame_types, vid->header->frames, 1);

	vid->bs = NHC_BS_new(file);
	NHC_BS_read(vid->bs, vid->header->trees_size);

	// vid->mmap_tree = NHC_VID_Tree_New(vid->bs);
	// vid->mclr_tree = NHC_VID_Tree_New(vid->bs);
	// vid->full_tree = NHC_VID_Tree_New(vid->bs);
	// vid->type_tree = NHC_VID_Tree_New(vid->bs);

	vid->surface = SDL_CreateRGBSurface(SDL_SWSURFACE, vid->header->width, vid->header->height, 8, 0, 0, 0, 0);
	vid->last_read_frame = -1;

	return vid;
}

int NHC_VID_frame(NHC_VID* vid, int frame) {
	if(frame >= 0) {
		if(frame < vid->header->frames) {
			vid->frame = frame;
		}
		else {
			vid->frame = 0;
		}
	}
	return vid->frame;
}

int NHC_VID_Read_Palette(NHC_VID* vid) {

}

int NHC_VID_Read_Audio(NHC_VID* vid) {

}

int NHC_VID_Read_Video(NHC_VID* vid) {

}

int NHC_VID_read_frame(NHC_VID* vid) {
	if(vid->frame == vid->last_read_frame) {
		return;
	}
	if(vid->frame < vid->last_read_frame) {
		int surface_len = vid->surface->h * vid->surface->pitch;
		Uint8* pixels = vid->surface->pixels;
		int i;
		for(i = 0; i < surface_len; i++) {
			pixels[i] = 0;
		}

		vid->last_read_frame = -1;
		NHC_BS_seek(vid->bs, 104 + 5 * vid->header->frames + vid->header->trees_size);
	}

	int frame;
	for(frame = vid->last_read_frame + 1; frame <= vid->frame; frame++) {
		NHC_BS_read(vid->bs, vid->frame_sizes[frame]);

		if(vid->frame - frame < NHC_VID_READ_FRAMES) {
			NHC_VID_Read_Palette(vid);
			NHC_VID_Read_Audio(vid);
			NHC_VID_Read_Video(vid);
		}
	}
}

MODULE = Games::Neverhood::Video		PACKAGE = Games::Neverhood::Video		PREFIX = Neverhood_Video_

NHC_VID*
Neverhood_Video_xs_new(CLASS, filename, hash)
		char* CLASS
		const char* filename
		SV* hash
	CODE:
		RETVAL = NHC_VID_new(filename);
		SvREFCNT_inc(hash);
		RETVAL->hash = hash;
	OUTPUT:
		RETVAL

SV*
Neverhood_Video_hash(vid)
		SV* vid
	CODE:
		if(SvTYPE(SvRV(vid)) == SVt_PVHV) {
			RETVAL = vid;
		}
		else {
			RETVAL = ((NHC_VID*) SvIV(SvRV(vid)))->hash;
		}
		SvREFCNT_inc(RETVAL);
	OUTPUT:
		RETVAL

int
Neverhood_Video_xs_frame(vid, frame)
		NHC_VID* vid
		int frame
	CODE:
		RETVAL = NHC_VID_frame(vid, frame);
	OUTPUT:
		RETVAL

void
Neverhood_Video_DESTROY(vid)
		NHC_VID* vid
	CODE:
		// SDL_RWclose(vid->bs->file);
		// SDL_FreeRW(vid->bs->file);
		// free(vid->bs);
		// free(vid->header);
		// free(vid->frame_sizes);
		// free(vid->frame_types);
		// free(vid);
