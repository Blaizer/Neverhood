// helper - general purpose stuff

#pragma once

#define SDL_MAIN_HANDLED
#include <SDL.h>

#ifndef NEVERHOOD_NO_PERL
// SDL is our stdio compatibility layer, not Perl
#define WIN32IO_IS_STDIO
#define WIN32SCK_IS_STDSCK
#include <EXTERN.h>
#include <perl.h>
#define NO_XSLOCKS
#include <XSUB.h>
#endif

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
#define New(nitems, type) (type*)SDL_malloc((nitems) * sizeof(type))
#define Copy(ptr, src, nitems, type) (void)SDL_memcpy(ptr, src, (nitems) * sizeof(type))
#define Set( ptr, val, nitems, type) (void)SDL_memset(ptr, val, (nitems) * sizeof(type))
#define Zero(ptr,      nitems, type) (void)SDL_memset(ptr, 0,   (nitems) * sizeof(type))
#define Free SDL_free
#define Renew(ptr, oldnitems, nitems, type) ptr = (type*)My_renew_(ptr, &(oldnitems), nitems, sizeof(type))
void* My_renew_ (void* ptr, int* oldnitems, int nitems, int size);

#define error(...) do {\
	fprintf(stderr, __VA_ARGS__);\
	fprintf(stderr, " at " __FILE__ " line %d\n", __LINE__);\
	fprintf(stderr, "-----\n");\
	exit(1);\
} while (0)

#define debug(...) do {\
	if (0) {\
		fprintf(stderr, __VA_ARGS__); fputc('\n', stderr);\
		fprintf(stderr, "----- at " __FILE__ " line %d\n", __LINE__);\
	}\
} while (0)

#define SDL_READ_LE16(x) SDL_SwapLE16(*(Uint16*)(x))
#define SDL_READ_LE32(x) SDL_SwapLE32(*(Uint32*)(x))
Uint8 SDL_Read8 (SDL_RWops* stream);
SDL_RWops* SDL_RWopen (const char* filename);

#define My_ISA(package, parent) My_isa_(package "::ISA", parent)
void My_isa_ (const char* isa, const char* parent);
