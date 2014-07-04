#include <helper.h>

void* My_new_ (int size)
{
	void* ptr = SDL_malloc(size);
	if (!ptr) SDL_OutOfMem();
	return ptr;
}

void* My_renew_ (void* ptr, int* oldnitems, int nitems, int size)
{
	if (!ptr) {
		*oldnitems = nitems;
		ptr = SDL_malloc(nitems * size);
		if (!ptr) SDL_OutOfMem();
	}
	else if (nitems > *oldnitems) {
		*oldnitems = nitems;
		ptr = SDL_realloc(ptr, nitems * size);
		if (!ptr) SDL_OutOfMem();
	}
	return ptr;
}

void SDL_SwapLE32n_ (Uint32* buf, int nitems) {
	Uint32* end = buf + nitems;
	while (buf < end)
		*buf++ = SDL_SwapLE32(*buf);
	}
}
void SDL_SwapLE16n_ (Uint16* buf, int nitems) {
	Uint16* end = buf + nitems;
	while (buf < end)
		*buf++ = SDL_SwapLE16(*buf);
	}
}

void My_isa_ (const char* isa, const char* parent)
{
	av_push(get_av(isa, GV_ADD), newSVpv(parent, 0));
}
