#include <helper.h>

void* My_renew_ (void* ptr, int* oldnitems, int nitems, int size)
{
	if (!ptr) {
		*oldnitems = nitems;
		return SDL_malloc(nitems * size);
	}
	else if (nitems > *oldnitems) {
		*oldnitems = nitems;
		return SDL_realloc(ptr, nitems * size);
	}
	return ptr;
}

Uint8 SDL_Read8 (SDL_RWops* stream)
{
	Uint8 num;
	SDL_RWread(stream, &num, 1, 1);
	return num;
}

// open a RWops file for reading and set error properly
SDL_RWops* SDL_RWopen (const char* filename)
{
	SDL_RWops* stream = SDL_RWFromFile(filename, "rb");
	if (!stream) SDL_SetError("Couldn't open %s: %s", filename, SDL_GetError());
	return stream;
}

void My_isa_ (const char* isa, const char* parent)
{
	av_push(get_av(isa, GV_ADD), newSVpv(parent, 0));
}
