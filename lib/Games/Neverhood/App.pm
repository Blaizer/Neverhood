# a class to overload methods of SDLx::App

use 5.01;
use strict;
use warnings;
package Games::Neverhood::App;

use parent qw/SDLx::App/;
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

1;
