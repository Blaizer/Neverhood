#include <Smacker.h>

// persistent memory for loading frames since none of this is threaded
static Uint8* _buffer;
static Sint32 _buffer_size;
static BitStream _bs;

static void BitStream_new (BitStream*, Uint8* buf, Uint32 size);
static bool BitStream_get_bit (BitStream*);
static Uint8 BitStream_get_8 (BitStream*);
static Uint16 BitStream_get_16 (BitStream*);
static void SmallTree_new (SmallTree*, BitStream* bs);
static Uint16 SmallTree_get_code (SmallTree*, BitStream* bs);
static void BigTree_new (BigTree*, BitStream* bs, Uint32 alloc_size);
static void BigTree_reset (BigTree*);
static Uint32 BigTree_get_code (BigTree*, BitStream* bs);
static void BigTree_DESTROY (BigTree*);

SmackerResource* SmackerResource_new (ArchiveEntry* entry)
{
	SmackerResource* self = New(1, SmackerResource);

	if (entry->type != 10)
		error("Wrong type for resource: %08X, type: %02X", entry->key, entry->type);

	SDL_RWops* stream = ArchiveEntry_get_stream(entry);
	self->stream = stream;

	self->header.signature = SDL_ReadBE32(stream);

	if (self->header.signature != 0x534D4B32)
		error("Invalid Smacker signature on resource: %08X", entry->key);

	Uint32 width = SDL_ReadLE32(stream);
	Uint32 height = SDL_ReadLE32(stream);
	self->frame_count = SDL_ReadLE32(stream);
	Sint32 frame_delay = SDL_ReadLE32(stream);

	self->frame_ticks =
		frame_delay > 0 ? frame_delay :
		frame_delay < 0 ? frame_delay / -100.0 :
		1.0;

	// Flags for whether the video has a ring frame, is y-interlaced, or is y-doubled
	// None of the videos in the game set these bits, so these flags aren't handled
	self->header.flags = SDL_ReadLE32(stream);

	int i;
	for (i = 0; i < 7; i++)
		self->header.audio_size[i] = SDL_ReadLE32(stream);

	self->header.trees_size = SDL_ReadLE32(stream);
	self->header.mmap_size = SDL_ReadLE32(stream);
	self->header.mclr_size = SDL_ReadLE32(stream);
	self->header.full_size = SDL_ReadLE32(stream);
	self->header.type_size = SDL_ReadLE32(stream);

	for (i = 0; i < 7; i++) {
		// AudioInfo - Frequency and format information for each sound track, up to 7 audio tracks.
		// The 32 constituent bits have the following meaning:
		// * bit 31 - indicates Huffman + DPCM compression
		// * bit 30 - indicates that audio data is present for this track
		// * bit 29 - 1 = 16-bit audio; 0 = 8-bit audio
		// * bit 28 - 1 = stereo audio; 0 = mono audio
		// * bit 27 - indicates Bink RDFT compression
		// * bit 26 - indicates Bink DCT compression
		// * bits 25-24 - unused
		// * bits 23-0 - audio sample rate
		Uint32 audio_info = SDL_ReadLE32(stream);
		self->header.audio_info[i].has_audio   = audio_info & 1 << 30;
		self->header.audio_info[i].is_16_bit   = audio_info & 1 << 29;
		self->header.audio_info[i].is_stereo   = audio_info & 1 << 28;
		self->header.audio_info[i].sample_rate = audio_info & 0xFFFFFF;

		if (audio_info & 1 << 31)
			self->header.audio_info[i].compression = SMK_COMPRESSION_DPCM;
		else if (audio_info & 1 << 27)
			self->header.audio_info[i].compression = SMK_COMPRESSION_RDFT;
		else if (audio_info & 1 << 26)
			self->header.audio_info[i].compression = SMK_COMPRESSION_DCT;
		else
			self->header.audio_info[i].compression = SMK_COMPRESSION_NONE;

		// only handle DPCM compression
		if (
			self->header.audio_info[i].has_audio
			&& self->header.audio_info[i].compression != SMK_COMPRESSION_DPCM
		)
			error("Unhandled Smacker audio: %d", (int)self->header.audio_info[i].compression);
	}

	// build our AudioQueue if we have audio
	if (self->header.audio_info[0].has_audio) {
		SDL_AudioFormat format = self->header.audio_info[0].is_16_bit ? AUDIO_S16SYS : AUDIO_S8;
		Uint8 channels         = self->header.audio_info[0].is_stereo ? 2 : 1;
		int rate               = self->header.audio_info[0].sample_rate;

		debug("format: %d-bit, channels: %u, rate: %d", format == AUDIO_S8 ? 8 : 16, channels, rate);
		AudioQueue_new(&self->audio_queue, SMACKER_QUEUE_NODES, format, channels, rate);
	}

	self->header.dummy = SDL_ReadLE32(stream);

	self->frame_sizes = New(self->frame_count, Sint32);
	for (i = 0; i < self->frame_count; i++)
		self->frame_sizes[i] = SDL_ReadLE32(stream);

	self->frame_types = New(self->frame_count, Uint8);
	SDL_RWread(stream, self->frame_types, self->frame_count, 1);

	Renew(_buffer, _buffer_size, self->header.trees_size, Uint8);
	SDL_RWread(stream, _buffer, self->header.trees_size, 1);

	BitStream_new(&_bs, _buffer, self->header.trees_size);

	BigTree_new(&self->mmap_tree, &_bs, self->header.mmap_size);
	BigTree_new(&self->mclr_tree, &_bs, self->header.mclr_size);
	BigTree_new(&self->full_tree, &_bs, self->header.full_size);
	BigTree_new(&self->type_tree, &_bs, self->header.type_size);

	self->surface = SDL_CreateRGBSurface(0, width, height, 8, 0, 0, 0, 0);
	self->palette = self->surface->format->palette;
	self->palette->refcount++;
	Zero(self->palette->colors, 256, SDL_Color);
	SDL_SetSurfacePalette(self->surface, _app.palette);
	self->use_palette = 1;

	self->cur_frame = -1;
	self->frame_data_start_pos = SDL_RWtell(stream);

	return self;
}

static void SmackerResource_unpack_palette (SmackerResource*);
static void SmackerResource_unpack_audio (SmackerResource*, Sint32 buffer_size, Sint32 unpacked_size);
static void SmackerResource_unpack_video (SmackerResource*);

void SmackerResource_next (SmackerResource* self)
{
	Sint64 start_pos = SDL_RWtell(self->stream);

	// cur_frame starts at -1 so we can do this
	self->cur_frame++;
	if (self->cur_frame >= self->frame_count) {
		SmackerResource_stop(self);
		return;
	}

	Sint32 buffer_size;
	Uint8 frame_type = self->frame_types[self->cur_frame];

	if (frame_type & 1) {
		buffer_size = 4 * SDL_Read8(self->stream) - 1;
		Renew(_buffer, _buffer_size, buffer_size, Uint8);
		SDL_RWread(self->stream, _buffer, buffer_size, 1);

		SmackerResource_unpack_palette(self);
	}

	int track;
	for (track = 0; track < 7; track++) {
		if (!(frame_type & 2 << track))
			continue;

		buffer_size = SDL_ReadLE32(self->stream) - 4;
		Sint32 unpacked_size = buffer_size;
		if (self->header.audio_info[0].compression == SMK_COMPRESSION_DPCM) {
			unpacked_size = SDL_ReadLE32(self->stream);
			buffer_size -= 4;
		}

		// If it's track 0, play the audio data
		if (track == 0 && self->header.audio_info[0].has_audio && buffer_size > 0 && unpacked_size > 0) {
			Renew(_buffer, _buffer_size, buffer_size, Uint8);
			SDL_RWread(self->stream, _buffer, buffer_size, 1);

			SmackerResource_unpack_audio(self, buffer_size, unpacked_size);
		}
		else if (buffer_size > 0) {
			// Ignore the rest of the audio tracks, if they exist
			SDL_RWseek(self->stream, buffer_size, SEEK_CUR);
		}
	}

	Sint32 frame_size = self->frame_sizes[self->cur_frame] & ~3;
	Sint64 frame_size_used = SDL_RWtell(self->stream) - start_pos;
	if (frame_size < frame_size_used) {
		error("Smacker actual frame size exceeds recorded frame size");
	}
	buffer_size = frame_size - frame_size_used;

	Renew(_buffer, _buffer_size, buffer_size, Uint8);
	SDL_RWread(self->stream, _buffer, buffer_size, 1);
	BitStream_new(&_bs, _buffer, buffer_size);

	SmackerResource_unpack_video(self);
}

static void SmackerResource_stop_audio (SmackerResource* self)
{
	if (!self->header.audio_info[0].has_audio) return;

	// unset _audio.smacker if it's us
	(void)SDL_AtomicCASPtr((void**)&_audio.smacker, self, NULL);

	AudioQueue_DESTROY(&self->audio_queue);
}

void SmackerResource_stop (SmackerResource* self)
{
	self->cur_frame = -1;

	SmackerResource_stop_audio(self);

	// reset the palette and surface
	Zero(self->palette->colors, 256, SDL_Color);
	self->palette->version++;
	Zero(self->surface->pixels, self->surface->h * self->surface->pitch, Uint8);

	SDL_RWseek(self->stream, self->frame_data_start_pos, SEEK_SET);
}

bool SmackerResource_is_stopped (SmackerResource* self)
{
	return self->cur_frame == -1;
}

static void SmackerResource_unpack_video (SmackerResource* self)
{
	enum {
		SMK_BLOCK_MONO,
		SMK_BLOCK_FULL,
		SMK_BLOCK_SKIP,
		SMK_BLOCK_FILL
	};

	BigTree_reset(&self->mmap_tree);
	BigTree_reset(&self->mclr_tree);
	BigTree_reset(&self->full_tree);
	BigTree_reset(&self->type_tree);

	int bw = self->surface->w / 4;
	int bh = self->surface->h / 4;
	int block = 0;
	int blocks = bw * bh;
	int stride = self->surface->pitch;
	Uint8* out;
	int i;

	#define INCREMENT_BLOCK \
		out = (Uint8*)self->surface->pixels + 4 * ((block / bw) * stride + (block % bw));\
		block++

	while (block < blocks) {
		Uint32 type = BigTree_get_code(&self->type_tree, &_bs);
		Uint32 run = ((type & 0xFF) >> 2) + 1;
		if (run >= 60) run = 128 << (run - 60);

		switch (type & 3) {
			case SMK_BLOCK_SKIP:
				block += run;
			break;
			case SMK_BLOCK_MONO:
				while (run-- && block < blocks) {
					INCREMENT_BLOCK;
					Uint32 clr = BigTree_get_code(&self->mclr_tree, &_bs);
					Uint32 map = BigTree_get_code(&self->mmap_tree, &_bs);
					Uint8 hi = clr >> 8;
					Uint8 lo = clr & 0xFF;
					for (i = 0; i < 4; i++) {
						out[0] = map & 1 ? hi : lo;
						out[1] = map & 2 ? hi : lo;
						out[2] = map & 4 ? hi : lo;
						out[3] = map & 8 ? hi : lo;
						out += stride;
						map >>= 4;
					}
				}
			break;
			case SMK_BLOCK_FULL:
				while (run-- && block < blocks) {
					INCREMENT_BLOCK;
					for (i = 0; i < 4; i++) {
						Uint32 p1 = BigTree_get_code(&self->full_tree, &_bs);
						Uint32 p2 = BigTree_get_code(&self->full_tree, &_bs);
						out[2] = p1 & 0xFF;
						out[3] = p1 >> 8;
						out[0] = p2 & 0xFF;
						out[1] = p2 >> 8;
						out += stride;
					}
				}
			break;
			case SMK_BLOCK_FILL:
				while (run-- && block < blocks) {
					INCREMENT_BLOCK;
					Uint32 col = (type >> 8) * 0x01010101;
					for (i = 0; i < 4; i++) {
						out[0] = out[1] = out[2] = out[3] = col;
						out += stride;
					}
				}
			break;
		}
	}

	#undef INCREMENT_BLOCK
}

static void SmackerResource_unpack_DPCM_audio (SmackerResource* self, Uint8* unpacked_buffer, Sint32 unpacked_size)
{
	if (!BitStream_get_bit(&_bs))
		return;

	bool is_stereo = BitStream_get_bit(&_bs);
	bool is_16_bit = BitStream_get_bit(&_bs);
	int is_stereo_bytes = (is_stereo ? 2 : 1);
	int is_16_bit_bytes = (is_16_bit ? 2 : 1);
	assert(is_stereo == self->header.audio_info[0].is_stereo);
	assert(is_16_bit == self->header.audio_info[0].is_16_bit);

	Uint8* cur_pos = unpacked_buffer;
	Uint8* cur_end = unpacked_buffer + unpacked_size;

	SmallTree audio_trees [4];
	int k;
	for (k = 0; k < is_stereo_bytes * is_16_bit_bytes; k++)
		SmallTree_new(&audio_trees[k], &_bs);

	Sint32 bases [2];

	// Base values, stored as big endian
	for (k = is_stereo_bytes - 1; k >= 0; k--) {
		if (is_16_bit)
			bases[k] = SDL_Swap16(BitStream_get_16(&_bs));
		else
			bases[k] = BitStream_get_8(&_bs);
	}

	// The base values are also the first samples
	goto WRITE_BASES;

	// Next follow the deltas, which are added to the corresponding base values and
	// are stored as little endian
	while (cur_pos < cur_end) {
		// If the sample is stereo, the data is stored for the left and right channel, respectively
		// (the exact opposite to the base values)
		for (k = 0; k < is_stereo_bytes; k++) {
			if (is_16_bit) {
				Uint8 lo = SmallTree_get_code(&audio_trees[k * 2],     &_bs);
				Uint8 hi = SmallTree_get_code(&audio_trees[k * 2 + 1], &_bs);
				bases[k] += hi << 8 | lo;
			}
			else {
				Sint8 delta = SmallTree_get_code(&audio_trees[k], &_bs);
				bases[k] += delta;
			}
		}

		WRITE_BASES:
		for (k = 0; k < is_stereo_bytes; k++) {
			if (is_16_bit)
				*(Uint16*)cur_pos = bases[k];
			else
				*cur_pos = bases[k] ^ 0x80;
			cur_pos += is_16_bit_bytes;
		}
	}
}

static void SmackerResource_unpack_audio (SmackerResource* self, Sint32 buffer_size, Sint32 unpacked_size)
{
	Uint8* unpacked_buffer = AudioQueue_next(&self->audio_queue, unpacked_size, SDL_FALSE);
	if (!unpacked_buffer) return;

	if (self->header.audio_info[0].compression == SMK_COMPRESSION_DPCM) {
		BitStream_new(&_bs, _buffer, buffer_size);
		SmackerResource_unpack_DPCM_audio(self, unpacked_buffer, unpacked_size);
	}

	AudioQueue_push(&self->audio_queue);

	// start playing the audio
	(void)SDL_AtomicSetPtr((void**)&_audio.smacker, self);
}

void SmackerResource_play_audio (SmackerResource* self, Uint8* buf, int size)
{
	// copy what can be copied from the queue into buf
	AudioQueue_copy(&self->audio_queue, buf, size);
}

static void SmackerResource_unpack_palette (SmackerResource* self)
{
	enum {
		SMK_PAL_SKIP = 0x80,
		SMK_PAL_COPY = 0x40
	};

	Uint8* p = _buffer;

	// make a copy of the current palette
	SDL_Color old_palette [256];
	Copy(old_palette, self->palette->colors, 256, SDL_Color);

	SDL_Palette* palette = self->palette;

	SDL_Color color;
	color.a = 255;

	int i = 0;
	while (i < 256) {
		Uint8 b0 = *p++;
		if (b0 & SMK_PAL_SKIP) {
			i += (b0 & ~SMK_PAL_SKIP) + 1;
		}
		else if (b0 & SMK_PAL_COPY) {
			Uint8 c = (b0 & ~SMK_PAL_COPY) + 1;
			Uint8 o = *p++;

			SDL_SetPaletteColors(palette, old_palette + o, i, c);
			i += c;
		}
		else { // SMK_PAL_FULL
			color.r = b0   << 2;
			color.g = *p++ << 2;
			color.b = *p++ << 2;

			SDL_SetPaletteColors(palette, &color, i++, 1);
		}
	}

	if (self->use_palette)
		App_set_palette(self->palette);
}

void SmackerResource_use_palette (SmackerResource* self)
{
	self->use_palette = 1;
	App_set_palette(self->palette);
}

void SmackerResource_draw_surface (SmackerResource* self, int x, int y)
{
	SDL_Rect dst;
	dst.x = x;
	dst.y = y;

	SDL_SetClipRect(_app.texture_surface, NULL);
	SDL_BlitSurface(self->surface, NULL, _app.texture_surface, &dst);
}

void SmackerResource_DESTROY (SmackerResource* self)
{
	SDL_RWclose(self->stream);
	SDL_FreeSurface(self->surface);
	SDL_FreePalette(self->palette);
	Free(self->frame_sizes);
	Free(self->frame_types);
	BigTree_DESTROY(&self->mmap_tree);
	BigTree_DESTROY(&self->mclr_tree);
	BigTree_DESTROY(&self->full_tree);
	BigTree_DESTROY(&self->type_tree);
	SmackerResource_stop_audio(self);
	Free(self);
}

//
// BitStream
// Provides a stream of bits fit to our needs.
//

static void BitStream_new (BitStream* self, Uint8* buf, Uint32 size)
{
	self->buf = buf;
	self->end = buf + size;
	self->bit_count = 0;
	self->cur_byte = 0;
}

static bool BitStream_get_bit (BitStream* self)
{
	if (self->bit_count <= 0) {
		assert(self->buf < self->end);
		self->cur_byte = *self->buf++;
		self->bit_count = 8;
	}

	bool v = self->cur_byte & 1;

	self->cur_byte >>= 1;
	self->bit_count--;

	return v;
}

static Uint8 BitStream_get_8 (BitStream* self)
{
	assert(self->buf < self->end);
	Uint8 v = self->cur_byte | *self->buf << self->bit_count;
	self->cur_byte = *self->buf++ >> (8 - self->bit_count);

	return v;
}

static Uint16 BitStream_get_16 (BitStream* self)
{
	assert(self->buf + 1 < self->end);
	Uint16 v = self->cur_byte | *self->buf++ << self->bit_count;
	v |= *self->buf << (self->bit_count + 8);
	self->cur_byte = *self->buf++ >> (8 - self->bit_count);

	return v;
}

static Uint8 BitStream_skip_peek_8 (BitStream* self, Uint8* peek_skip)
{
	Uint8 peek;
	if (self->buf == self->end)
		peek = self->cur_byte;
	else
		peek = self->cur_byte | *self->buf << self->bit_count;

	Uint8 skip = peek_skip[peek];
	assert(skip <= 8);
	self->bit_count -= skip;

	if (self->bit_count < 0) {
		assert(self->buf < self->end);
		self->bit_count += 8;
		self->cur_byte = *self->buf++ >> (8 - self->bit_count);
	}
	else
		self->cur_byte >>= skip;

	return peek;
}

//
// SmallTree
// A Huffman-tree to hold 8-bit values.
//

#define SMK_SMALL_NODE 0x8000

static Uint16 SmallTree_decode_tree (SmallTree* self, BitStream* bs, Uint32 prefix, int size)
{
	if (!BitStream_get_bit(bs)) { // Leaf
		self->tree[self->tree_size] = BitStream_get_8(bs);

		if (size <= 8) {
			int i;
			for (i = 0; i < 256; i += 1 << size) {
				self->prefix_tree[prefix | i] = self->tree_size;
				self->prefix_size[prefix | i] = size;
			}
		}
		self->tree_size++;

		return 1;
	}

	Uint16 t = self->tree_size++;

	if (size == 8) {
		self->prefix_tree[prefix] = t;
		self->prefix_size[prefix] = 8;
	}

	Uint16 r1 = SmallTree_decode_tree(self, bs, prefix, size + 1);

	self->tree[t] = SMK_SMALL_NODE | r1;

	Uint16 r2 = SmallTree_decode_tree(self, bs, prefix | 1 << size, size + 1);

	return r1 + r2 + 1;
}

static void SmallTree_new (SmallTree* self, BitStream* bs)
{
	self->tree_size = 0;

	bool bit = BitStream_get_bit(bs);
	assert(bit);

	Set(self->prefix_tree, 0, 256, Uint16);
	Set(self->prefix_size, 0, 256, Uint8);

	SmallTree_decode_tree(self, bs, 0, 0);

	bit = BitStream_get_bit(bs);
	assert(!bit);
}

static Uint16 SmallTree_get_code (SmallTree* self, BitStream* bs)
{
	Uint8 peek = BitStream_skip_peek_8(bs, self->prefix_size);
	Uint16* p = &self->tree[self->prefix_tree[peek]];

	while (*p & SMK_SMALL_NODE) {
		if (BitStream_get_bit(bs))
			p += *p & ~SMK_SMALL_NODE;
		p++;
	}

	return *p;
}

//
// BigTree
// A Huffman-tree to hold 16-bit values.
//

#define SMK_BIG_NODE 0x80000000

static Uint32 BigTree_decode_tree (BigTree* self, BitStream* bs, Uint32 prefix, int size)
{
	bool bit = BitStream_get_bit(bs);
	if (!bit) { // Leaf
		Uint32 lo = SmallTree_get_code(self->byte_trees + 0, bs);
		Uint32 hi = SmallTree_get_code(self->byte_trees + 1, bs);

		Uint32 v = hi << 8 | lo;

		self->tree[self->tree_size] = v;

		int i;
		if (size <= 8) {
			for (i = 0; i < 256; i += 1 << size) {
				self->prefix_tree[prefix | i] = self->tree_size;
				self->prefix_size[prefix | i] = size;
			}
		}

		for (i = 0; i < 3; i++) {
			if (self->markers[i] == v) {
				self->last[i] = self->tree_size;
				self->tree[self->tree_size] = 0;
			}
		}
		self->tree_size++;

		return 1;
	}

	Uint32 t = self->tree_size++;

	if (size == 8) {
		self->prefix_tree[prefix] = t;
		self->prefix_size[prefix] = 8;
	}

	Uint32 r1 = BigTree_decode_tree(self, bs, prefix, size + 1);

	self->tree[t] = SMK_BIG_NODE | r1;

	Uint32 r2 = BigTree_decode_tree(self, bs, prefix | 1 << size, size + 1);

	return r1 + r2 + 1;
}

static void BigTree_new (BigTree* self, BitStream* bs, Uint32 alloc_size)
{
	bool bit = BitStream_get_bit(bs);
	if (!bit) {
		self->tree = New(1, Uint32);
		self->tree[0] = 0;
		self->last[0] = self->last[1] = self->last[2] = 0;
		return;
	}

	Set(self->prefix_tree, 0, 256, Uint32);
	Set(self->prefix_size, 0, 256, Uint8);

	SmallTree_new(self->byte_trees + 0, bs);
	SmallTree_new(self->byte_trees + 1, bs);

	self->markers[0] = BitStream_get_16(bs);
	self->markers[1] = BitStream_get_16(bs);
	self->markers[2] = BitStream_get_16(bs);

	self->last[0] = self->last[1] = self->last[2] = 0xFFFFFFFF;

	self->tree_size = 0;
	self->tree = New(alloc_size / 4, Uint32);

	BigTree_decode_tree(self, bs, 0, 0);

	bit = BitStream_get_bit(bs);
	assert(!bit);

	int i;
	for (i = 0; i < 3; i++) {
		if (self->last[i] == 0xFFFFFFFF) {
			self->last[i] = self->tree_size;
			self->tree[self->tree_size++] = 0;
		}
	}
}

static void BigTree_DESTROY (BigTree* self)
{
	Free(self->tree);
}

static void BigTree_reset (BigTree* self)
{
	self->tree[self->last[0]] = self->tree[self->last[1]] = self->tree[self->last[2]] = 0;
}

static Uint32 BigTree_get_code (BigTree* self, BitStream* bs)
{
	Uint8 peek = BitStream_skip_peek_8(bs, self->prefix_size);
	Uint32* p = &self->tree[self->prefix_tree[peek]];

	while (*p & SMK_BIG_NODE) {
		if (BitStream_get_bit(bs))
			p += *p & ~SMK_BIG_NODE;
		p++;
	}

	Uint32 v = *p;
	if (v != self->tree[self->last[0]]) {
		self->tree[self->last[2]] = self->tree[self->last[1]];
		self->tree[self->last[1]] = self->tree[self->last[0]];
		self->tree[self->last[0]] = v;
	}

	return v;
}

/*

MODULE=Neverhood::Smacker  PACKAGE=Neverhood::SmackerResource  PREFIX=SmackerResource_

SmackerResource*
SmackerResource_new (const char* CLASS, ArchiveEntry* entry)
	C_ARGS: entry

void
SmackerResource_DESTROY (SmackerResource* SELF)

void
SmackerResource_next (SmackerResource* SELF)

void
SmackerResource_stop (SmackerResource* SELF)

bool
SmackerResource_is_stopped (SmackerResource* SELF)

void
SmackerResource_use_palette (SmackerResource* SELF)

void
SmackerResource_draw_surface (SmackerResource* SELF, int x, int y)

void
SmackerResource_set_use_palette (SmackerResource* SELF, bool new)
	CODE:
		SELF->use_palette = new;

int
SmackerResource_cur_frame (SmackerResource* SELF)
	CODE:
		RETVAL = SELF->cur_frame;
	OUTPUT: RETVAL

Sint32
SmackerResource_frame_count (SmackerResource* SELF)
	CODE:
		RETVAL = SELF->frame_count;
	OUTPUT: RETVAL

double
SmackerResource_frame_ticks (SmackerResource* SELF)
	CODE:
		RETVAL = SELF->frame_ticks;
	OUTPUT: RETVAL

int
SmackerResource_w (SmackerResource* SELF)
	CODE:
		RETVAL = SELF->surface->w;
	OUTPUT: RETVAL

int
SmackerResource_h (SmackerResource* SELF)
	CODE:
		RETVAL = SELF->surface->h;
	OUTPUT: RETVAL

# */
