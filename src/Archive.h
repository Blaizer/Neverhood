// Archive - loads Blb archives into entries used to load the resources
//
// Based on the ScummVM Neverhood Engine's BlbArchive code

#pragma once
#include <helper.h>
#include <blast.h>

typedef Uint32 ArchiveKey;

typedef struct {
	char* filename;
	SDL_RWops* stream;
	Sint16 ext_data_size;
	Sint32 file_size;
	Sint32 file_count;
	ArchiveKey* keys;
	Uint8* ext_data;
	int iterator;
} Archive;

typedef struct {
	char* filename;
	ArchiveKey key;
	Uint8 type;
	Uint8 compr_type;
	Uint8* ext_data;
	Uint32 time_stamp;
	Sint32 offset;
	Sint32 disk_size;
	Sint32 size;
} ArchiveEntry;

// This module is a bit weird.
// It's a bit 2-in-1 with both Archive and ArchiveEntry.
// The Archive stuff just separates the C code from the
// Perl-specific code. So that's why it's like that.

Archive* Archive_new (Archive*, char* filename);
ArchiveEntry* Archive_next_entry (Archive*);
void Archive_DESTROY (Archive*);

Uint8* ArchiveEntry_get_buffer (ArchiveEntry*);
Uint8* ArchiveEntry_get_buffer_from (ArchiveEntry*, SDL_RWops* stream, Uint8* out_buffer, Uint8* in_buffer);
SDL_RWops* ArchiveEntry_get_stream (ArchiveEntry*);

void ArchiveEntry_DESTROY (ArchiveEntry*);
void ArchiveEntry_redirect (ArchiveEntry*, ArchiveEntry* entry);
