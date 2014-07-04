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
	Uint16 ext_data_size;
	Uint32 file_size;
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
	Uint32 offset;
	Uint32 disk_size;
	Uint32 size;
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

/*

MODULE=Neverhood::Archive  PACKAGE=Neverhood::Archive  PREFIX=Archive_

Archive*
Archive_new (const char* CLASS, char* filename)
		Archive* self = New(1, Archive);
	C_ARGS: self, filename

void
Archive_DESTROY (Archive* SELF)
	CLEANUP:
		Free(SELF);

ArchiveEntry*
Archive_next_entry (Archive* SELF)
		const char* CLASS = "Neverhood::ArchiveEntry";

MODULE=Neverhood::Archive  PACKAGE=Neverhood::ArchiveEntry  PREFIX=ArchiveEntry_

void
ArchiveEntry_DESTROY (ArchiveEntry* SELF)

void
ArchiveEntry_redirect (ArchiveEntry* SELF, ArchiveEntry* entry)

ArchiveKey
ArchiveEntry_key_from_int (Uint32 key)
	CODE:
		RETVAL = key;
	OUTPUT: RETVAL

const char*
ArchiveEntry_filename (ArchiveEntry* SELF)
	CODE:
		RETVAL = SELF->filename;
	OUTPUT: RETVAL

ArchiveKey
ArchiveEntry_key (ArchiveEntry* SELF)
	CODE:
		RETVAL = SELF->key;
	OUTPUT: RETVAL

Uint8
ArchiveEntry_type (ArchiveEntry* SELF)
	CODE:
		RETVAL = SELF->type;
	OUTPUT: RETVAL

Uint8
ArchiveEntry_compr_type (ArchiveEntry* SELF)
	CODE:
		RETVAL = SELF->compr_type;
	OUTPUT: RETVAL

Uint32
ArchiveEntry_time_stamp (ArchiveEntry* SELF)
	CODE:
		RETVAL = SELF->time_stamp;
	OUTPUT: RETVAL

Sint32
ArchiveEntry_offset (ArchiveEntry* SELF)
	CODE:
		RETVAL = SELF->offset;
	OUTPUT: RETVAL

Sint32
ArchiveEntry_disk_size (ArchiveEntry* SELF)
	CODE:
		RETVAL = SELF->disk_size;
	OUTPUT: RETVAL

Sint32
ArchiveEntry_size (ArchiveEntry* SELF)
	CODE:
		RETVAL = SELF->size;
	OUTPUT: RETVAL

# */
