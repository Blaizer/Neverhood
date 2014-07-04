// helper - general purpose stuff

#pragma once

#define SDL_MAIN_HANDLED
#include <SDL.h>

#define USE_PERLIO
#define PERLIO_NOT_STDIO 0
#undef USE_STDIO
#undef USE_SFIO

#include <EXTERN.h>
#include <perl.h>

#include <stdio.h>
#include <stdlib.h>
#include <memory.h>
#include <string.h>

#undef New
#undef Newz
#undef Newx
#undef Newxz
#undef Renew
#undef Renewx
#undef Copy
#undef Copyx
#undef Set
#undef Setx
#undef Free
#undef Freex
#undef Zero
#define New(nitems, type) (type*)My_new_((nitems) * sizeof(type))
#define Renew(ptr, oldnitems, nitems, type) ptr = (type*)My_renew_(ptr, &(oldnitems), nitems, sizeof(type))
#define Copy(ptr, src, nitems, type) (void)SDL_memcpy(ptr, src, (nitems) * sizeof(type))
#define Set( ptr, val, nitems, type) (void)SDL_memset(ptr, val, (nitems) * sizeof(type))
#define Zero(ptr,      nitems, type) (void)SDL_memset(ptr, 0,   (nitems) * sizeof(type))
#define Free SDL_free
void* My_new_ (int size);
void* My_renew_ (void* ptr, int* oldnitems, int nitems, int size);

#define debug(...) do {\
	if (0) {\
		fprintf(stderr, __VA_ARGS__); fputc('\n', stderr);\
		fprintf(stderr, "----- at " __FILE__ " line %d\n", __LINE__);\
	}\
} while (0)

#if SDL_BYTEORDER == SDL_BIG_ENDIAN
	#define SDL_SwapLE32n(buf, nitems) SDL_SwapLE32n_((Uint32*)buf, nitems)
	#define SDL_SwapLE16n(buf, nitems) SDL_SwapLE16n_((Uint16*)buf, nitems)
#else
	#define SDL_SwapLE32n(buf, nitems) do {} while(0)
	#define SDL_SwapLE16n(buf, nitems) do {} while(0)
#endif
void SDL_SwapLE32n_ (Uint32* buf, int nitems);
void SDL_SwapLE16n_ (Uint16* buf, int nitems);

#define SDL_READ_BE16(x) SDL_SwapBE16(*(Uint16*)(x))
#define SDL_READ_BE32(x) SDL_SwapBE32(*(Uint32*)(x))
#define SDL_READ_LE16(x) SDL_SwapLE16(*(Uint16*)(x))
#define SDL_READ_LE32(x) SDL_SwapLE32(*(Uint32*)(x))
