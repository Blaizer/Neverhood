#include <Audio.h>

Audio _audio;

#define AUDIO_CHANNELS 8

static void Audio_mixer (void* udata, Uint8* buf, int size);

void Audio_init ()
{
	SDL_AudioSpec want;
	want.freq     = 44100;
	want.format   = AUDIO_S16LSB;
	want.channels = 2;
	want.samples  = 2048;
	want.callback = Audio_mixer;
	want.userdata = NULL;

	if (App_get_option_IV("info")) {
		int i;

		printf("Audio devices:\n");
		for (i = 0; i < SDL_GetNumAudioDevices(0); i++) {
			const char* name = SDL_GetAudioDeviceName(i, 0);
			printf("\t%s\n", name);
		}

		const char* cur = SDL_GetCurrentAudioDriver();
		printf("Current audio driver:\n\t%s\n", cur);

		printf("Audio drivers:\n");
		for (i = 0; i < SDL_GetNumAudioDrivers(); i++) {
			const char* name = SDL_GetAudioDriver(i);
			printf("\t%s\n", name);
		}
	}

	_audio.device = SDL_OpenAudioDevice(NULL, 0, &want, &_audio.spec, SDL_AUDIO_ALLOW_ANY_CHANGE);
	if (_audio.device <= 0)
		error("Could not open audio device");

	if (!App_get_option_IV("mute"))
		_audio.volume = SDL_MIX_MAXVOLUME;

	(void)SDL_AtomicSet(&_audio.playback_rate, 1);

	SDL_PauseAudioDevice(_audio.device, 0);
}

static void Audio_mixer (void* udata, Uint8* buf, int size)
{
	(void)udata;
	Zero(buf, size, Uint8);
	if (!_audio.buf) {
		_audio.buf = New(size, Uint8);
		_audio.spec.samples = size;
	}

	MusicResource* music = _audio.music;
	SmackerResource* smacker = SDL_AtomicGetPtr((void**)&_audio.smacker);

	if (music) {
		MusicResource_play(music, _audio.buf, size);

		SDL_MixAudioFormat(buf, _audio.buf, AUDIO_S16LSB, size, _audio.volume);
	}
	if (smacker) {
		SmackerResource_play_audio(smacker, _audio.buf, size);

		SDL_MixAudioFormat(buf, _audio.buf, AUDIO_S16LSB, size, _audio.volume);
	}
}

void Audio_new_cvt (SDL_AudioCVT* cvt, SDL_AudioFormat format, Uint8 channels, int freq)
{
	SDL_BuildAudioCVT(
		cvt,
		format, channels, freq,
		_audio.spec.format, _audio.spec.channels, _audio.spec.freq
	);
}

void AudioQueue_new (AudioQueue* self, int nodes, SDL_AudioFormat format, Uint8 channels, int rate)
{
	self->n = nodes;

	self->nodes = New(self->n, AudioNode);
	Zero(self->nodes, self->n, AudioNode);
	self->buf = NULL;

	// start the cur and tail at the first node
	self->cur = self->tail = self->nodes;

	// the amount of nodes that can be safely claimed with next()
	self->empty_node = SDL_CreateSemaphore(self->n);

	// the amount of nodes that can be copied out to audio
	self->full_node = SDL_CreateSemaphore(0);

	// create cvt now
	Audio_new_cvt(&self->cvt, format, channels, rate);
}

void AudioQueue_destroy_buffers (AudioQueue* self)
{
	int i;
	for (i = 0; i < self->n; i++) {
		if (self->nodes[i].buf) {
			Free(self->nodes[i].buf);
			self->nodes[i].buf = NULL;
		}
	}
}

void AudioQueue_DESTROY (AudioQueue* self)
{
	AudioQueue_destroy_buffers(self);
	Free(self->nodes);
	self->nodes = NULL;
	self->n = 0;
	SDL_DestroySemaphore(self->empty_node);
	SDL_DestroySemaphore(self->full_node);
	self->empty_node = self->full_node = NULL;
}

Uint8* AudioQueue_next (AudioQueue* self, int size, bool wait)
{
	if (wait) SDL_SemWait(self->empty_node);
	else if (SDL_SemTryWait(self->empty_node)) return NULL;

	AudioNode* node = self->tail;

	SDL_AudioCVT* cvt = &self->cvt;

	Renew(node->buf, node->alloc_size, size * cvt->len_mult, Uint8);
	cvt->buf = node->buf;
	cvt->len = size;

	node->size = size * cvt->len_mult;
	return node->buf;
}

void AudioQueue_push (AudioQueue* self)
{
	SDL_ConvertAudio(&self->cvt);

	// the node is ready to be used
	SDL_SemPost(self->full_node);

	// move to the next node and wrap if necessary
	if (++self->tail - self->nodes >= self->n) self->tail = self->nodes;
}

int AudioQueue_copy (AudioQueue* self, Uint8* buf, int size)
{
	if (size <= 0) return 0;
	if (SDL_SemValue(self->full_node) > 0) {
		if (!self->buf) self->buf = self->cur->buf;
		int cur_size = self->cur->size - (self->buf - self->cur->buf);
		int size_taken = SDL_min(size, cur_size);

		Copy(buf, self->buf, size_taken, Uint8);

		cur_size -= size_taken;
		if (cur_size <= 0) {
			// move to the next node
			SDL_SemPost(self->empty_node);
			if (++self->cur - self->nodes >= self->n) self->cur = self->nodes;
			self->buf = NULL;

			buf  += size_taken;
			size -= size_taken;
			SDL_SemWait(self->full_node); // this never blocks
			return size_taken + AudioQueue_copy(self, buf, size);
		}
		else {
			// didn't use the entire current node
			self->buf += size_taken;
			return size_taken;
		}
	}
	else {
		Zero(buf, size, Uint8);
		return 0;
	}
}

void AudioQueue_unblock (AudioQueue* self)
{
	SDL_SemPost(self->empty_node);
	SDL_SemPost(self->full_node);
}

static int MusicResource_load_music (void* udata);

// The amount of nodes to cycle between when streaming music.
// Any number >1 works.
#define MUSIC_QUEUE_NODES 2

MusicResource* MusicResource_new (ArchiveEntry* entry)
{
	MusicResource* self = New(1, MusicResource);

	if (entry->type != 8)
		error("Wrong type for resource: %08X, type: %X", entry->key, entry->type);

	debug("music: %08X, shift: %02X", entry->key, *entry->ext_data);

	self->entry = entry;
	self->stop = 0;

	AudioQueue_new(&self->queue, MUSIC_QUEUE_NODES, AUDIO_S16LSB, 1, 22050);

	// spawn a thread to load the music from drive
	self->thread = SDL_CreateThread(MusicResource_load_music, NULL, self);

	return self;
}

// SoundResource* SoundResource_new (ArchiveEntry* entry)
// {
// 	SoundResource* self = New(1, SoundResource);

// 	Uint8 shift = *self->entry->ext_data;
// 	Sint32 size = self->entry->size;

// 	SDL_AudioCVT cvt;
// 	Audio_new_cvt(&cvt, AUDIO_S16LSB, 1, 22050);

// 	SDL_RWops* stream = ArchiveEntry_get_stream(self->entry);

// 	bool compressed = shift != 0xFF;
// 	cvt.len = size * (compressed ? 1 : 2);
// 	cvt.buf = New(cvt.len * cvt.len_mult, Uint8);

// 	Uint8* input_buf = compressed ? cvt.buf + size : cvt.buf;
// 	SDL_RWread(stream, input_buf, size, 1);

// 	Sint16 cur_value = 0;
// 	Audio_unpack_audio(input_buf, cvt.buf, size, shift, &cur_value);
// 	SDL_ConvertAudio(&cvt);

// 	self->buf = cvt.buf;
// 	self->size = cvt.len * cvt.len_ratio;
// }

static int MusicResource_load_music (void* udata)
{
	MusicResource* self = (MusicResource*)udata;

	SDL_RWops* stream = ArchiveEntry_get_stream(self->entry);
	Uint8 shift = *self->entry->ext_data;
	bool compressed = shift != 0xFF;

	Uint8* output_buffer = NULL;
	Sint32 size = 0;
	Sint32 remaining_size = self->entry->size;
	Sint16 cur_value = 0;

	// want audio samples bytes of usable data at the end, so divide by
	// what we would normally multiply by to get the output size
	Sint32 unpacked_size = _audio.spec.samples / self->queue.cvt.len_ratio;

	// audio unpacks to twice the size if DW ADPCM compressed
	int unpacking_mult = compressed ? 2 : 1;

	// we need less input if we get more by unpacking
	Sint32 node_size = unpacked_size / unpacking_mult;

	while (!self->stop) {
		// we're at the start of a new node
		if (size <= 0) {
			size = node_size;
			output_buffer = AudioQueue_next(&self->queue, unpacked_size, SDL_TRUE);
		}

		Sint32 size_taken = SDL_min(size, remaining_size);
		remaining_size -= size_taken;
		size -= size_taken;

		Uint8* input_buffer = compressed ? output_buffer + size_taken : output_buffer;

		if (self->stop) break;
		SDL_RWread(stream, input_buffer, size_taken, 1);
		if (self->stop) break;

		if (shift != 0xFF) {
			// DW ADPCM compressed
			Sint16* output_buf = (Sint16*)output_buffer;
			Sint8* input_buf = (Sint8*)input_buffer;
			Sint8* input_end = input_buf + size_taken;
			while (input_buf < input_end) {
				cur_value += *input_buf++;
				*output_buf++ = SDL_SwapLE16(cur_value << shift);
			}
		}

		if (size > 0) {
			// unfinished buffer
			output_buffer += size_taken * unpacking_mult;
		}
		else {
			// convert and push the buffer we got with "next" to the queue
			AudioQueue_push(&self->queue);
		}

		if (remaining_size <= 0) {
			// loop back to the start of the audio
			SDL_RWseek(stream, self->entry->offset, SEEK_SET);
			remaining_size = self->entry->size;
			cur_value = 0;
		}
	}

	SDL_RWclose(stream);
	AudioQueue_destroy_buffers(&self->queue);

	return 0;
}

void MusicResource_play (MusicResource* self, Uint8* buf, int size)
{
	// copy what can be copied from the queue into buf
	AudioQueue_copy(&self->queue, buf, size);
}

void MusicResource_fade_in (MusicResource* self, int ms)
{
	SDL_LockAudio();

	// if (self != _playing->music) {
	// 	if (ms > 0) {
	// 		self->fading = MIX_FADING_IN;
	// 		self->fade_step = 0;
	// 		self->fade_steps = ms / _playing->ms_per_step;
	// 	}
	// 	else {
	// 		self->fading = MIX_NO_FADING;
	// 	}

		_audio.music = self;
	// }

	SDL_UnlockAudio();
}

void MusicResource_fade_out (MusicResource* self, int ms)
{
	if (!self) return;

	SDL_LockAudio();

	if (self == _audio.music) {
		if (ms <= 0) {  // just halt immediately.
			_audio.music = NULL;
		}
		// else {
		// 	int fade_steps = (ms + _playing->ms_per_step - 1) / _playing->ms_per_step;
		// 	if (self->fading == MIX_NO_FADING) {
		// 		self->fade_step = 0;
		// 	}
		// 	else {
		// 		int step;
		// 		int old_fade_steps = self->fade_steps;
		// 		if (self->fading == MIX_FADING_OUT) {
		// 			step = self->fade_step;
		// 		}
		// 		else {
		// 			step = old_fade_steps - self->fade_step + 1;
		// 		}
		// 		self->fade_step = (step * fade_steps) / old_fade_steps;
		// 	}
		// 	self->fading = MIX_FADING_OUT;
		// 	self->fade_steps = fade_steps;
		// }
	}

	SDL_UnlockAudio();
}

int MusicResource_fade (MusicResource* self)
{
	int volume = 128;
	// if (self->fading != MIX_NO_FADING) {
	// 	if (self->fade_step++ < self->fade_steps) {
	// 		int fade_step  = self->fade_step;
	// 		int fade_steps = self->fade_steps;

	// 		if (self->fading == MIX_FADING_OUT) {
	// 			volume = (volume * (fade_steps-fade_step) / fade_steps);
	// 		}
	// 		else { // Fading in
	// 			volume = (volume * fade_step / fade_steps);
	// 		}
	// 		// debug("fading volume: %03d\n", volume);
	// 	}
	// 	else {
	// 		if (self->fading == MIX_FADING_OUT) { // finished fading out
	// 			_playing->music = NULL;
	// 		}
	// 		else
	// 			self->fading = MIX_NO_FADING; // finished fading in
	// 	}
	// }
	return volume;
}

void MusicResource_DESTROY (MusicResource* self)
{
	// stop audio thread
	MusicResource_fade_out(self, 0);

	// stop loading thread
	self->stop = 1;
	AudioQueue_unblock(&self->queue);
	SDL_WaitThread(self->thread, NULL);

	AudioQueue_DESTROY(&self->queue);
	Free(self);
}
