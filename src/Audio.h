// Audio - Play audio

#pragma once
#include <helper.h>
#include <App.h>
#include <Archive.h>

typedef struct {
	Uint8* buf;
	Sint32 size, alloc_size;
} AudioNode;

typedef struct {
	AudioNode* nodes, * cur, * tail;
	Uint8* buf;
	int n;
	SDL_sem* full_node, * empty_node;

	int playback_rate;
	bool got_playback_rate;
	SDL_AudioFormat cvt_format;
	Uint8 cvt_channels;
	int cvt_rate;
	SDL_AudioCVT cvt;
} AudioQueue;

void AudioQueue_new (AudioQueue* self, int nodes, SDL_AudioFormat format, Uint8 channels, int rate);
void AudioQueue_destroy_buffers (AudioQueue*);
void AudioQueue_DESTROY (AudioQueue*);
SDL_AudioCVT* AudioQueue_cvt (AudioQueue*);
Uint8* AudioQueue_next (AudioQueue*, int size, bool wait);
void AudioQueue_push (AudioQueue*);
int AudioQueue_copy (AudioQueue*, Uint8* buf, int size);
void AudioQueue_unblock (AudioQueue*);

typedef struct {
	SDL_AudioSpec spec;
	SDL_AudioDeviceID device;
	struct MusicResource* music;
	struct SmackerResource* smacker;
	Uint8* buf;
	int volume;
	SDL_atomic_t playback_rate;
} Audio;

extern Audio _audio;

void Audio_init ();
void Audio_new_cvt (SDL_AudioCVT* cvt, SDL_AudioFormat format, Uint8 channels, int rate);

typedef struct MusicResource {
	// used by audio loading thread
	ArchiveEntry* entry;

	// used by audio loading and playing threads
	AudioQueue queue;
	bool stop;
	SDL_Thread* thread;

	// used by audio playing thread
	int fading;
	int fade_step;
	int fade_steps;
} MusicResource;

MusicResource* MusicResource_new (ArchiveEntry* entry);
void MusicResource_play (MusicResource*, Uint8* buf, int size);
void MusicResource_fade_in (MusicResource*, int ms);
void MusicResource_fade_out (MusicResource*, int ms);
int MusicResource_fade (MusicResource*);
void MusicResource_DESTROY (MusicResource*);

typedef struct {
	SoundResource* sound;
	bool playing;
	bool paused;
	bool looping;
	int volume;
	int pan;
} SoundChannel;

#include <Smacker.h>
