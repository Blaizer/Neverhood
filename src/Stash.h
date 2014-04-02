#include <helper.h>

typedef SV* Stash;

#define Stash_GET(self, type, obj) do {\
	self = INT2PTR(type*, Stash_get_iv(obj));\
	if (!self) {\
		self = New(1, type);\
		Stash_BUILD((SV**)self, obj);\
	}\
} while(0)

void Stash_BUILD (Stash*, SV* obj);
IV Stash_get_iv (SV* obj);
void Stash_set_sv (Stash*, SV* obj);
void Stash_call_method (Stash*, const char* name);
void Stash_DEMOLISH (Stash*);
