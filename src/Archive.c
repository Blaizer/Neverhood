#include <Archive.h>

#define AR_HEADER 16
#define AR_KEY 4
#define AR_ENTRY 20
#define AR_BOTH (AR_KEY + AR_ENTRY)

Archive* Archive_new (Archive* self, char* filename)
{
	self->stream   = NULL;
	self->keys     = NULL;
	self->ext_data = NULL;
	self->entries  = NULL;

	SDL_RWops* stream = SDL_RWFromFile(filename, "rb");
	SDL_assert_release(stream);

	self->filename = filename;
	self->stream = stream;

	Sint64 size = SDL_RWsize(stream);
	SDL_assert_release(size >= 0);

	Uint8 header [AR_HEADER];
	int read = SDL_RWread(stream, header, AR_HEADER, 1);
	SDL_assert_release(read == AR_HEADER);

	Uint32 magic        = SDL_READ_BE32(header);
	Uint16 id           = SDL_READ_LE16(header + 4);
	self->ext_data_size = SDL_READ_LE16(header + 6);
	self->file_size     = SDL_READ_LE32(header + 8);
	self->file_count    = SDL_READ_LE32(header + 12);

	SDL_assert_release(magic == 0x40490002);
	SDL_assert_release(id == 7);
	SDL_assert_release((Sint64)self->file_size == size);
	SDL_assert_release(self->file_count >= 0);
	SDL_assert_release(self->file_count <= (0xFFFFFFFF - AR_HEADER - self->ext_data_size) / AR_BOTH);

	self->keys = New(self->file_count, AR_KEY);
	SDL_assert_release(self->keys);

	read = SDL_RWread(stream, self->keys, self->file_count * AR_KEY, 1);
	SDL_assert_release(read == self->file_count * AR_KEY);
	SDL_SwapLE32n(self->keys, self->file_count);

	if (self->ext_data_size) {
		Uint32 ext_data_pos = AR_HEADER + self->file_count * AR_BOTH;
		Sint64 seek = SDL_RWseek(stream, ext_data_pos, SEEK_SET);
		SDL_assert_release(seek == ext_data_pos);

		self->ext_data = New(self->ext_data_size, Uint8);
		SDL_assert_release(self->ext_data);

		read = SDL_RWread(stream, self->ext_data, self->ext_data_size, 1);
		SDL_assert_release(read == self->ext_data_size);
	}

	self->iterator = -1;
	return self;
}

ArchiveEntry* Archive_next_entry (Archive* self)
{
	if (self->iterator == -1) {
		Uint32 entries_pos = AR_HEADER + self->file_count * AR_KEY;
		Sint64 seek = SDL_RWseek(self->stream, entries_pos, SEEK_SET) < 0;
		SDL_assert_release(seek == entries_pos);
		self->iterator = 0;
	}
	else if (self->iterator >= self->file_count) {
		// so we can start again next time
		self->iterator = -1;
		return NULL;
	}

	ArchiveEntry* entry = New(1, ArchiveEntry);
	SDL_assert_release(entry);

	Uint8 buffer [AR_ENTRY];
	int read = SDL_RWread(entry->stream, buffer, AR_ENTRY, 1);
	SDL_assert_release(read == AR_ENTRY);

	entry->key             = self->keys[self->iterator];
	entry->type            =             *(buffer);
	entry->compr_type      =             *(buffer + 1);
	Uint16 ext_data_offset = SDL_READ_LE16(buffer + 2);
	entry->time_stamp      = SDL_READ_LE32(buffer + 4);
	entry->offset          = SDL_READ_LE32(buffer + 8);
	entry->disk_size       = SDL_READ_LE32(buffer + 12);
	entry->size            = SDL_READ_LE32(buffer + 16);

	if (self->ext_data && ext_data_offset-- && ext_data_offset < self->ext_data_size)
		entry->ext_data = self->ext_data + ext_data_offset;
	else
		entry->ext_data = NULL;

	self->iterator++;
	return entry;

	ERROR:
	Free(entry);
	SDL_SetError("Error in \"%s\", entry %08X: %s", self->filename, self->keys[self->iterator], SDL_GetError());
	self->iterator++; // continue to the next entry anyway
	return NULL;
}

void Archive_DESTROY (Archive* self)
{
	SDL_RWclose(self->stream);
	Free(self->keys);
	Free(self->ext_data);
	Free(self);
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
