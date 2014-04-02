#include <helper.h>

// The purpose of this file is to link of the rest of the C together into a single library.
// The C that it's linking together is from code that has been Parse::XS'd.
// So you'll need to call all their boot functions to get all XSUBs installed.
// This is non-trivial. It's done in Neverhood::Base::Util.
// Booting them all could potentially be done here, but I couldn't get it working perfectly.

MODULE=Neverhood::XS  PACKAGE=Neverhood::XS  PREFIX=Neverhood_XS_

void
Neverhood_XS_this_function_doesnt_actually_do_anything ()
	CODE:
