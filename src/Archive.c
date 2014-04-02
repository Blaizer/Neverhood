#include <Archive.h>

Archive* Archive_new (Archive* self, char* filename)
{
	SDL_RWops* stream = SDL_RWopen(filename);
	self->filename = filename;
	self->stream = stream;

	Uint32 id1          = SDL_ReadLE32(stream);
	Uint16 id2          = SDL_ReadLE16(stream);
	self->ext_data_size = SDL_ReadLE16(stream);
	self->file_size     = SDL_ReadLE32(stream);
	self->file_count    = SDL_ReadLE32(stream);

	// get the size of the file just for an error check
	Sint64 size = SDL_RWseek(stream, 0, SEEK_END);
	if (id1 != 0x02004940 || id2 != 7 || self->file_size != size)
		error("Archive %s seems to be corrupt", filename);

	if (self->ext_data_size) {
		// ext_data_pos = header_size + file_count * (key_size + entry_size)
		Sint32 ext_data_pos = 16 + self->file_count * (4 + 20);
		SDL_RWseek(stream, ext_data_pos, SEEK_SET);
		self->ext_data = New(self->ext_data_size, Uint8);
		SDL_RWread(stream, self->ext_data, self->ext_data_size, 1);
	}
	else {
		self->ext_data = NULL;
	}

	// seek back to where the keys are
	SDL_RWseek(stream, 16, SEEK_SET);
	self->keys = New(self->file_count, ArchiveKey);
	int i;
	for (i = 0; i < self->file_count; i++) {
		self->keys[i] = SDL_ReadLE32(stream);
	}
	// now we're where we need to be for loading the entries with next_entry

	self->iterator = 0;
	return self;
}

ArchiveEntry* Archive_next_entry (Archive* self)
{
	if (self->iterator >= self->file_count) {
		self->iterator = 0; // so we can start again next time
		return NULL;
	}

	ArchiveEntry* entry = New(1, ArchiveEntry);
	SDL_RWops* stream = self->stream;

	entry->filename        = self->filename;
	entry->key             = self->keys[self->iterator];
	entry->type            = SDL_Read8(stream);
	entry->compr_type      = SDL_Read8(stream);
	Uint16 ext_data_offset = SDL_ReadLE16(stream);
	entry->time_stamp      = SDL_ReadLE32(stream);
	entry->offset          = SDL_ReadLE32(stream);
	entry->disk_size       = SDL_ReadLE32(stream);
	entry->size            = SDL_ReadLE32(stream);

	entry->ext_data
		= self->ext_data && ext_data_offset
		? self->ext_data + ext_data_offset - 1
		: NULL;

	self->iterator++;

	return entry;
}

void Archive_DESTROY (Archive* self)
{
	SDL_RWclose(self->stream);
	Free(self->keys);
	// ext_data isn't freed here because we need it forever anyways
	// filenames are also needed
}

// callbacks for blast
static unsigned ArchiveEntry_infun (void* how, unsigned char** buf)
{
	void** in = (void**)how;

	Uint8* in_buf = (Uint8*)in[0];
	Sint32 size = *(Sint32*)in[1];

	*buf = in_buf;
	return size;
}
static int ArchiveEntry_outfun (void* how, unsigned char* buf, unsigned size)
{
	Uint8** out_buf = (Uint8**)how;

	Copy(*out_buf, buf, size, Uint8);
	*out_buf += size;
	return 0;
}

// stream will be opened and closed if it is NULL
// out_buffer will be created and returned if it is NULL
// in_buffer will be created and destroyed if it is NULL
Uint8* ArchiveEntry_get_buffer_from (ArchiveEntry* self, SDL_RWops* stream, Uint8* out_buffer, Uint8* in_buffer)
{
	bool my_stream     = !stream;
	bool my_out_buffer = !out_buffer;
	bool my_in_buffer  = !in_buffer;

	if (my_stream) stream = SDL_RWopen(self->filename);
	SDL_RWseek(stream, self->offset, SEEK_SET);

	switch (self->compr_type) {
		case 1: { // Uncompressed
			if (my_out_buffer) out_buffer = New(self->size, Uint8);
			SDL_RWread(stream, out_buffer, self->size, 1);
			if (my_stream) SDL_RWclose(stream);
			break;
		}
		case 3: { // DCL-compressed
			if (my_out_buffer) out_buffer = New(self->size, Uint8);
			Uint8* out = out_buffer;

			if (my_in_buffer) in_buffer = New(self->disk_size, Uint8);
			SDL_RWread(stream, in_buffer, self->disk_size, 1);
			if (my_stream) SDL_RWclose(stream);

			void* in[2];
			in[0] = in_buffer;
			in[1] = &self->disk_size;

			int err = blast(ArchiveEntry_infun, in, ArchiveEntry_outfun, &out);
			if (err) error("Blast error: %d; filekey: %08X", err, self->key);

			if (my_in_buffer) Free(in_buffer);
			break;
		}
		default:
			error("Unknown compression type: %d; filekey: %08X", self->compr_type, self->key);
	}

	return out_buffer;
}

Uint8* ArchiveEntry_get_buffer (ArchiveEntry* self)
{
	return ArchiveEntry_get_buffer_from(self, NULL, NULL, NULL);
}

SDL_RWops* ArchiveEntry_get_stream (ArchiveEntry* self)
{
	if (self->compr_type != 1)
		error("Can't get stream from compression type: %d; filekey: %08X", self->compr_type, self->key);

	SDL_RWops* stream = SDL_RWopen(self->filename);
	Sint64 off = SDL_RWseek(stream, self->offset, SEEK_SET);

	if (off != self->offset)
		error("Couldn't get stream for filekey: %08X", self->key);

	return stream;
}

void ArchiveEntry_DESTROY (ArchiveEntry* self)
{
	Free(self);
}

void ArchiveEntry_redirect (ArchiveEntry* self, ArchiveEntry* entry)
{
	// set everything but the key to the values of the other entry
	self->filename   = entry->filename;
	self->type       = entry->type;
	self->compr_type = entry->compr_type;
	self->ext_data   = entry->ext_data;
	self->time_stamp = entry->time_stamp;
	self->offset     = entry->offset;
	self->disk_size  = entry->disk_size;
	self->size       = entry->size;
}

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
