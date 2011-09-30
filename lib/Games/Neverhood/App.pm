# a class to overload methods of SDLx::App

use 5.01;
use strict;
use warnings;
package Games::Neverhood::App;

use parent qw/SDLx::App/;
use SDL::Events;
# use SDL::Mixer::Music;
# use SDL::Mixer::Channels;

# overload of pause for pre and post pause
sub pause {
	my ($self, $callback) = @_;

	# SDL::Mixer::Music::pause_music;
	# SDL::Mixer::Channels::pause(-1);

	$self->SUPER::pause($callback);

	# SDL::Mixer::Music::resume_music;
	# SDL::Mixer::Channels::resume(-1);
}

# overload of the method eoq is responsible for
# stop on quit event or alt-f4
sub _exit_on_quit {
	my ($self, $e) = @_;
	if(
		$e->type == SDL_QUIT
		or
		$e->type == SDL_KEYDOWN and $e->key_sym == SDLK_F4
		and $e->key_mod & KMOD_ALT and not $e->key_mod & (KMOD_CTRL | KMOD_SHIFT | KMOD_META)
	) {
		$self->stop;
		return 1;
	}
	return;
}

1;
