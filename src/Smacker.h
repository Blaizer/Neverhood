// Smacker - decode smacker movie files and play them
//
// Based heavily on the ScummVM v1.3.1 Smacker decoder (video/smkdecoder).
// https://github.com/scummvm/scummvm/tree/42ab839dd6c8a1570b232101eb97f4e54de57935/video
// Unlike that decoder this one only aims for SMK2 compatability

#pragma once

#include <helper.h>
#include <App.h>
#include <Archive.h>
#include <Audio.h>

// I played through all the videos in the game and the highest I've seen needed is 25
#define SMACKER_QUEUE_NODES 32

typedef struct {
	Uint8* buf;
	Uint8* end;
	Sint8 bit_count;
	Uint8 cur_byte;
} BitStream;

typedef struct {
	Sint16 tree_size;
	Uint16 tree [511];

	Uint16 prefix_tree [256];
	Uint8  prefix_size [256];
} SmallTree;

typedef struct {
	Sint32 tree_size;
	Uint32* tree;
	Uint32 last [3];

	Uint32 prefix_tree [256];
	Uint8  prefix_size [256];

	// Used during construction
	Uint32 markers [3];
	SmallTree byte_trees [2];
} BigTree;

typedef struct SmackerResource {
	int cur_frame;

	SDL_RWops* stream;
	SDL_Surface* surface;
	SDL_Palette* palette;
	bool use_palette;

	struct {
		Uint32 signature;
		Uint32 flags;
		Sint32 audio_size [7];
		Sint32 trees_size;
		Sint32 mmap_size;
		Sint32 mclr_size;
		Sint32 full_size;
		Sint32 type_size;
		Sint32 dummy;
		struct {
			enum {
				SMK_COMPRESSION_NONE,
				SMK_COMPRESSION_DPCM,
				SMK_COMPRESSION_RDFT,
				SMK_COMPRESSION_DCT
			} compression;
			bool has_audio;
			bool is_16_bit;
			bool is_stereo;
			Sint32 sample_rate;
		} audio_info [7];
	} header;

	Sint32* frame_sizes;
	// The FrameTypes section of a Smacker file contains an array of bytes, where
	// the 8 bits of each byte describe the contents of the corresponding frame.
	// The highest 7 bits correspond to audio frames (bit 7 is track 6, bit 6 track 5
	// and so on), so there can be up to 7 different audio tracks. When the lowest bit
	// (bit 0) is set, it denotes a frame that contains a palette record
	Uint8* frame_types;
	Sint64 frame_data_start_pos;

	double frame_ticks;
	Sint32 frame_count;

	BigTree mmap_tree;
	BigTree mclr_tree;
	BigTree full_tree;
	BigTree type_tree;

	AudioQueue audio_queue;
} SmackerResource;

SmackerResource* SmackerResource_new (ArchiveEntry* entry);
void SmackerResource_next (SmackerResource*);
void SmackerResource_stop (SmackerResource*);
bool SmackerResource_is_stopped (SmackerResource*);
void SmackerResource_play_audio (SmackerResource*, Uint8* buf, int size);
void SmackerResource_use_palette (SmackerResource* self);
void SmackerResource_DESTROY (SmackerResource*);
