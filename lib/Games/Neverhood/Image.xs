#include "perl.h"
#include "XSUB.h"
#include <string.h>
#include "SDL.h"

MODULE = Games::Neverhood::Image		PACKAGE = Games::Neverhood::Image		PREFIX = Neverhood_Image_

void
Neverhood_Image_load(filename, mirror)
		char* filename
		int mirror
	CODE:
		return;

void
Neverhood_Image_load_sequence(filename, frame, mirror)
		char* filename
		int frame
		int mirror
	CODE:
		return;
