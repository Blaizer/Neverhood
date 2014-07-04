#include <App.h>

App _app;

static void App_init_options ();
static void App_quit ();

void App_init ()
{
	// not using SDL_Main as entry point so call this before SDL_Init
	SDL_SetMainReady();

	if (SDL_Init(SDL_INIT_VIDEO|SDL_INIT_AUDIO) < 0)
		error("SDL initialization failed");

	atexit(App_quit);

	_app.stash = get_sv(";", 0);
	App_init_options();

	// Uint32 flags = SDL_OPENGL;
	// if (App_getOptionIV("fullscreen"))
		// flags |= SDL_FULLSCREEN;
	// if (App_getOptionIV("frameless"))
		// flags |= SDL_NOFRAME;
	// if (App_getOptionIV("resizable"))
		// flags |= SDL_RESIZABLE;

	// App_setVsync();
}

static void App_do_first ();
static void App_on_event (SDL_Event* event);
static void App_draw ();
static void App_next ();
static void App_stop ();
static void App_do_pause ();
static SV* App_get_method (const char* method);
static void App_call_method (SV* method);
static void App_set_icon ();
static char* App_get_format_name (Uint32 format);

void App_run ()
{
	_app.window = SDL_CreateWindow(
		"The Neverhood",
		SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
		640, 480,
		SDL_WINDOW_HIDDEN|SDL_WINDOW_RESIZABLE
	);
	if (!_app.window)
		error("Create window failed");

	_app.renderer = SDL_CreateRenderer(_app.window, -1, SDL_RENDERER_ACCELERATED);
	if (!_app.renderer)
		error("Create renderer failed");

	App_set_icon();

	// show the window now to avoid a slight bit of flicker :-)
	SDL_ShowWindow(_app.window);

	SDL_RenderSetLogicalSize(_app.renderer, 640, 480);
	SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "linear");

	SDL_GetWindowSize(_app.window, &_app.window_w, &_app.window_h);

	int max_w, max_h;

	{
		bool info_option = App_get_option_IV("info");

		int display = SDL_GetWindowDisplayIndex(_app.window);
		SDL_DisplayMode desktop_mode;
		SDL_GetDesktopDisplayMode(display, &desktop_mode);
		max_w = desktop_mode.w;
		max_h = desktop_mode.h;

		if (info_option) {
			printf("Display modes:\n");
		}

		int i;
		for (i = 0; i < SDL_GetNumDisplayModes(display); i++) {
			SDL_DisplayMode mode;
			SDL_GetDisplayMode(display, i, &mode);

			if (info_option) {
				char* format = App_get_format_name(mode.format);
				printf("\t%2d: %4d x %4d @ %3dHz - %s\n", i, mode.w, mode.h, mode.refresh_rate, format);
			}

			max_w = SDL_max(max_w, mode.w);
			max_h = SDL_max(max_h, mode.h);
		}

		SDL_RendererInfo info;
		SDL_GetRendererInfo(_app.renderer, &info);
		max_w = SDL_max(max_w, info.max_texture_width);
		max_h = SDL_max(max_h, info.max_texture_height);

		if (info_option) {
			printf("Renderer:\n\t%s\n", info.name);

			printf("Renderer modes:\n");
			Uint32 i;
			for (i = 0; i < info.num_texture_formats; i++) {
				char* format = App_get_format_name(info.texture_formats[i]);
				printf(
					"\t%5d x %5d - %s\n",
					info.max_texture_width, info.max_texture_height,
					format
				);
			}
		}
	}

	_app.texture = SDL_CreateTexture(
		_app.renderer,
		SDL_PIXELFORMAT_ARGB8888,
		SDL_TEXTUREACCESS_STREAMING,
		max_w, max_h
	);
	if (!_app.texture)
		error("Create texture failed");

	// allocate the surface that'll be mapped to the game texture
	_app.texture_surface = SDL_CreateRGBSurface(
		0,
		max_w, max_h, 32,
		0x00FF0000,
		0x0000FF00,
		0x000000FF,
		0xFF000000
	);
	App_set_texture_surface_rect(0, 0, 640, 480);

	// allocate the surface that'll be drawn to before drawing to the texture surface
	_app.palette_surface = SDL_CreateRGBSurface(
		0,
		max_w, max_h, 8,
		0, 0, 0, 0
	);
	SDL_SetColorKey(_app.palette_surface, SDL_TRUE, 0);
	_app.palette = _app.palette_surface->format->palette;

	// doing this once speeds up subsequent calls
	App_render_texture_surface();
	SDL_RenderPresent(_app.renderer);

	Audio_init();

	SDL_DisableScreenSaver();
	App_set_vsync(1);

	_app.first = 1;

	_app.method.draw      = App_get_method("draw");
	_app.method.render    = App_get_method("render");
	_app.method.first     = App_get_method("first");
	_app.method.next      = App_get_method("next");
	_app.method.on_space  = App_get_method("on_space");
	_app.method.on_escape = App_get_method("on_escape");

	OUTER_LOOP: while (!_app.stop)
	{
		_app.restart = 0;

		Uint32 max_ticks = 200; // prevent too big tick jumps by capping cycle updates to this
		Uint32 min_delay = 1;   // always delay by at least this amount to prevent CPU hogging
		double max_fps = 30.0;  // max fps to cap at

		App_do_pause();
		if (_app.restart) continue;

		App_do_first();
		if (_app.restart) continue;

		// some calculations
		double min_ticks = 1000.0 / max_fps;
		double rate_ticks = _app.frame_ticks / floor( _app.frame_ticks / (min_ticks - 1e-6) );
		if (rate_ticks < min_ticks) rate_ticks = min_ticks;

		double delay_frame_count = 0.0;
		double frame_count = 0.0;
		Uint32 base_ticks = SDL_GetTicks();

		while (1)
		{
			// Draw

			App_draw();
			assert(!_app.restart);

			// Delay

			Uint32 new_ticks = SDL_GetTicks();

			#define TARGET_TICKS(frame_count, rate_ticks) (base_ticks + (Uint32)round((frame_count) * (rate_ticks)))
			delay_frame_count += 1.0;
			Uint32 target_ticks = TARGET_TICKS(delay_frame_count, rate_ticks);

			Uint32 delay;
			if (target_ticks >= new_ticks) {
				delay = target_ticks - new_ticks;
			}
			else {
				delay = 0;

				// Uint32 delta_ticks = new_ticks - prev_ticks;
				// if (max_ticks > 0 && delta_ticks > max_ticks) {
				// 	// move base_ticks ahead by the amount the delta is bigger than max_ticks
				// 	base_ticks += delta_ticks - max_ticks;
				// }

				delay_frame_count = ceil( (double)(new_ticks - base_ticks) / rate_ticks );
			}
			delay = SDL_max(delay, min_delay);
			SDL_Delay(delay);
			new_ticks += delay;

			// Events

			SDL_Event event;
			while (SDL_PollEvent(&event))
			{
				App_on_event(&event);
				if (_app.restart) goto OUTER_LOOP;
			}

			// Next

			target_ticks = TARGET_TICKS(frame_count + 1.0, _app.frame_ticks);
			while (target_ticks <= new_ticks)
			{
				frame_count += 1.0;

				App_next();
				if (_app.restart) goto OUTER_LOOP;

				target_ticks = TARGET_TICKS(frame_count + 1.0, _app.frame_ticks);
			}
			#undef TARGET_TICKS
		}
	}
}

static void App_quit ()
{
	SDL_Quit();
}

static void App_do_first ()
{
	if (!_app.first) return;
	_app.first = 0;

	// App_first must set frame_ticks
	_app.frame_ticks = 0;

	App_call_method(_app.method.first);

	if (
		_app.frame_ticks <= 0
		// not setting frame_ticks is permissable if we're about to stop or first again
		&& !_app.stop && !_app.first
	)
		error("first() didn't set frame ticks");
}

static void App_do_pause ()
{
	if (!_app.pause) return;
	_app.pause = 0;

	// SDL_Event event;
	// SDL_WaitEvent(&event)
}

static void App_draw ()
{
	SDL_SetRenderDrawColor(_app.renderer, 0, 0, 0, 255);
	SDL_RenderClear(_app.renderer);
	SDL_FillRect(_app.texture_surface, &_app.texture_surface_rect, 0);

	App_call_method(_app.method.draw);
	App_render_texture_surface();
	App_call_method(_app.method.render);

	SDL_RenderPresent(_app.renderer);
}

static void App_next ()
{
	App_call_method(_app.method.next);
}

void App_set_frame_ticks (double ticks)
{
	_app.frame_ticks = ticks;
}

static void App_init_options ()
{
	SV* rv = get_sv(";", 0);
	if (rv && sv_isobject(rv)) {
		SV* sv = SvRV(rv);
		if (SvTYPE(sv) == SVt_PVHV) {
			_app.options = (HV*)sv;
		}
	}
	if (!_app.options)
		error("$; is not an object");
}

SV* App_get_option (const char* name)
{
	SV** value = hv_fetch(_app.options, name, strlen(name), 0);
	if (value && *value && SvOK(*value))
		return *value;
	else
		return NULL;
}

IV App_get_option_IV (const char* name)
{
	SV* value = App_get_option(name);
	if (value && SvIOK(value))
		return SvIV(value);
	else
		return 0;
}

char* App_get_option_PV (const char* name)
{
	SV* value = App_get_option(name);
	if (value && SvIOK(value))
		return SvPV_nolen(value);
	else
		return NULL;
}

void App_stop ()
{
	// Make it look like we closed faster than we really did
	SDL_SetRenderDrawColor(_app.renderer, 0, 0, 0, 255);
	SDL_RenderClear(_app.renderer);
	SDL_RenderPresent(_app.renderer);
	SDL_HideWindow(_app.window);

	_app.stop = 1;
	_app.restart = 1;
}

void App_restart ()
{
	_app.first = 1;
	_app.restart = 1;
}

void App_pause ()
{
	_app.pause = 1;
	_app.restart = 1;
}

static void App_stop_on_event (SDL_Event* event)
{
	switch (event->type) {
		case SDL_QUIT: {
			App_stop();
			break;
		}
		case SDL_KEYDOWN: {
			Uint16 mod = event->key.keysym.mod;

			if (
				event->key.keysym.sym == SDLK_F4
				&& mod & KMOD_ALT
				&& !(mod & (KMOD_CTRL|KMOD_SHIFT))
			) {
				App_stop();
			}
			break;
		}
	}
}

static void App_on_event (SDL_Event* event)
{
	App_stop_on_event(event);
	if (_app.restart) return;

	switch (event->type) {
		case SDL_QUIT: {
			App_stop();
			break;
		}
		case SDL_WINDOWEVENT: {
			switch (event->window.event) {
				// case SDL_WINDOWEVENT_ENTER:
				// case SDL_WINDOWEVENT_LEAVE:
				// 	break;
				// case SDL_WINDOWEVENT_FOCUS_GAINED:
				// case SDL_WINDOWEVENT_FOCUS_LOST:
				// 	break;
				case SDL_WINDOWEVENT_SIZE_CHANGED:
					_app.window_w = event->window.data1;
					_app.window_h = event->window.data2;
					break;
			}
			break;
		}
		case SDL_KEYDOWN: {
			Uint16 mod = event->key.keysym.mod;
			Uint16 ctrl = mod & KMOD_CTRL;
			Uint16 shift = mod & KMOD_SHIFT;
			Uint16 alt = mod & KMOD_ALT;

			if (event->key.keysym.sym == SDLK_SPACE) {
				App_call_method(_app.method.on_space);
			}
			else if (event->key.keysym.sym == SDLK_ESCAPE) {
				App_call_method(_app.method.on_escape);
			}
			// else if (event->key.keysm.sym == SDLK_F8 && !ctrl && !shift && !alt) {
			// 	handle_pause();
			// }
			break;
		}
		// case SDL_MOUSEMOTION: {
		// 	Uint8 down = event->motion.state == SDL_PRESSED;
		// 	handle_mouse(event->motion.x, event->motion.y, 0, down);
		// }
		// case SDL_MOUSEBUTTONDOWN:
		// case SDL_MOUSEBUTTONUP: {
		// 	Uint8 down = event->button.state == SDL_PRESSED;
		// 	handle_mouse(event->button.x, event->button.y, 1, down);
		// }
	}
}

static SV* App_get_method (const char* method)
{
	HV* stash = SvSTASH(SvRV(_app.stash));
	GV* gv = gv_fetchmethod(stash, method);
	CV* cv = GvCV(gv);

	if(cv == Nullcv)
		croak("Not a subroutine reference");

	return MUTABLE_SV(cv);
}

static void App_call_method (SV* method)
{
	dSP;

	PUSHMARK(SP);
	XPUSHs(_app.stash);
	PUTBACK;

	call_sv(method, G_VOID|G_DISCARD);
}

void App_set_texture_surface_rect (int x, int y, int w, int h)
{
	_app.texture_surface_rect.x = x;
	_app.texture_surface_rect.y = y;
	_app.texture_surface_rect.w = w;
	_app.texture_surface_rect.h = h;
}

void App_render_texture_surface ()
{
	SDL_UpdateTexture(_app.texture,
		&_app.texture_surface_rect, _app.texture_surface->pixels, _app.texture_surface->pitch);
	SDL_RenderCopy(_app.renderer, _app.texture, &_app.texture_surface_rect, NULL);
	// SDL_RenderCopyEx(_app.renderer, _app.texture, &_app.texture_surface_rect, NULL, 0, NULL, SDL_FLIP_NONE);
}

void App_set_palette (SDL_Palette* palette)
{
	App_set_palette_colors(palette, 0, palette->ncolors);
}

void App_set_palette_colors (SDL_Palette* palette, int i, int n)
{
	SDL_SetPaletteColors(_app.palette, palette->colors, i, n);
}

void App_set_vsync (bool vsync) {
	SDL_SetHint("SDL_HINT_RENDER_VSYNC", vsync ? "1" : "0");
	SDL_GL_SetSwapInterval(vsync ? 1 : 0);
}

void App_set_render_color (Uint8 r, Uint8 g, Uint8 b, Uint8 a) {
	SDL_SetRenderDrawColor(_app.renderer, r, g, b, a);
}

void App_render_rect (SDL_Rect* rect)
{
	SDL_RenderDrawRect(_app.renderer, rect);
}

void App_render_bounds (SDL_Rect* bounds)
{
	SDL_Rect rect;
	rect.x = bounds->x;
	rect.y = bounds->y;
	rect.w = bounds->w - bounds->x + 1;
	rect.h = bounds->h - bounds->y + 1;
	App_render_rect(&rect);
}

static void App_set_icon ()
{
	// bitmap in big endian 16 bit R5 G6 B5 format
	Uint32 icon_pixels [] = {
		0x1ff81ff8,0x1ff81ff8,0x1ff86eb4,0x8b8b1ff8,0x1ff81ff8,0x1ff81ff8,0x1ff81ff8,0x1ff81ff8,
		0x00020002,0x00020002,0x00026672,0xebd3c87a,0x00020002,0x00020002,0x00020002,0x00020002,
		0x0002e007,0xe007e007,0xe007a00e,0x83436ee4,0x8877e007,0xe007e007,0xe007e007,0xe0070002,
		0x0002e007,0xe007e007,0xe007e007,0xafb67af7,0xdbf7297f,0xe007e007,0xe007e007,0xe0070002,
		0x0002e007,0xe007e007,0xe007e007,0xd1d437ff,0xf8f693e5,0xe007e007,0xe007e007,0xe0070002,
		0x0002e007,0xe007e007,0xe007e007,0xebcbc9a2,0x54fe688a,0xe007e007,0xe007e007,0xe0070002,
		0x0002e007,0xe007e007,0xe007e007,0xe99b4a93,0x6ecc2772,0xe007e007,0xe007e007,0xe0070002,
		0x0002e007,0xe007e007,0xe007e007,0x888d4dbc,0x6ee48c9b,0xe007e007,0xe007e007,0xe0070002,
		0x0002e007,0xe007e007,0xe007e007,0x865dcfec,0x6eecc674,0xe007e007,0xe007e007,0xe0070002,
		0x0002e007,0xe007e007,0xe007a32e,0xc9d28eeb,0x8ce38665,0xe007e007,0xe007e007,0xe0070002,
		0x0002e007,0xe007e007,0xe007e137,0xc8a2a6b1,0x68b209c2,0x8bb3e007,0xe007e007,0xe0070002,
		0x0002e007,0xe007e007,0xe007e007,0x0004c158,0xa360c02c,0xe007e007,0xe007e007,0xe0070002,
		0x0002e007,0xe007e007,0xe007e007,0xa00e8120,0x8033e007,0xe007e007,0xe007e007,0xe0070002,
		0x0002e007,0xe007e007,0xe007e007,0xe5458028,0x0014e007,0xe007e007,0xe007e007,0xe0070002,
		0x0002e007,0xe0072337,0xc99c8cbb,0x23598020,0x611ae007,0xe007e007,0xe007e007,0xe0070002,
		0x00020002,0x0002a559,0x0662a661,0x0662c130,0x6018a659,0xc1300002,0x00020002,0x00020002
	};

	#if SDL_BYTEORDER == SDL_LIL_ENDIAN
	{
		Uint32* p = icon_pixels;
		Uint32* e = p + 16*8;
		for (; p < e; p++) *p = SDL_Swap32(*p);
	}
	#endif

	SDL_Surface* icon_surface = SDL_CreateRGBSurfaceFrom(
		icon_pixels,
		16, 16, 16, 16*2,
		0xf800,
		0x07e0,
		0x001f,
		0x0000
	);
	SDL_SetColorKey(icon_surface, SDL_TRUE, SDL_SwapBE16(0x1ff8));

	SDL_SetWindowIcon(_app.window, icon_surface);
	SDL_FreeSurface(icon_surface);
}

static char* App_get_format_name (Uint32 format)
{
	return (char*)SDL_GetPixelFormatName(format) + 16;
}
