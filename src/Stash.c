#include <Stash.h>

void Stash_BUILD (Stash* self, SV* obj)
{
	*self = newSVsv(obj);
	(void)hv_store((HV*)SvRV(obj), "STASH", 5, newSViv(PTR2IV(self)), 0);
}

IV Stash_get_iv (SV* obj)
{
	SV** val = hv_fetch((HV*)SvRV(obj), "STASH", 5, 0);
	if (!val) return 0;
	return SvIV(*val);
}

void Stash_set_sv (Stash* self, SV* obj)
{
	if (self) sv_setsv(obj, *self);
}

void Stash_call_method (Stash* self, const char* name)
{
	if (!self || !*self) return;

	dSP;

	PUSHMARK(SP);
	XPUSHs(*self);
	PUTBACK;

	call_method(name, G_VOID|G_DISCARD);
}

void Stash_DEMOLISH (Stash* self)
{
	SvREFCNT_dec(*self);
	Free(self);
}

/*

MODULE=Neverhood::Stash  PACKAGE=Neverhood::Stash  PREFIX=Stash_

void
Stash_DEMOLISH (Stash* SELF, ...)

# */
