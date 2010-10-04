package Games::Neverhood;
use 5.01;
use strict;
use warnings;
our $VERSION = 0.001;

use SDL;
use SDLx::App;
use SDL::Events;
use SDL::Video;
use SDL::Mouse;
use File::ShareDir;
use Data::Dumper;

our %M = (
	# folder => File::ShareDir::dist_dir('Games-Neverhood'),
	%M,
	fullscreen   => $ARGV[0] ? 0 : SDL_FULLSCREEN,
	mouse        => [],
);

$ENV{SDL_VIDEO_CENTERED} = 1;
our $App = SDLx::App->new(
	w => 640,
	h => 480,
	d => 32,
	title => 'The Neverhood',
	$M{fullscreen} ? () : (min_t => 0),
	flags =>
		# SDL_ASYNCBLIT |
		# SDL_SWSURFACE |
		SDL_HWSURFACE |

		SDL_ANYFORMAT |
		SDL_HWPALETTE |
		SDL_HWACCEL |
		SDL_DOUBLEBUF |
		$M{fullscreen} |
		SDL_NOFRAME |
		# SDL_PREALLOC |

		0,
);
SDL::Mouse::show_cursor(SDL_DISABLE);
SDL::Video::wm_set_icon(SDL::Image::load("$M{folder}/misc/icon.png" or die SDL::get_error));

sub init { $App->run }

use Games::Neverhood::Scene;
use Games::Neverhood::Holder;
use Games::Neverhood::Sprite;
use Games::Neverhood::Cursors;
use Games::Neverhood::Klaymen;
our $Klaymen;

use Games::Neverhood::Scene::Nursery;

$Games::Neverhood::Scene::Nursery1->set;

#####################################EVENT###################################

sub stop {
	my ($e) = @_;
	$App->stop if $e->type == SDL_QUIT
	or $e->type == SDL_KEYDOWN and $e->key_sym == SDLK_ESCAPE;
}

sub window {
	my ($e) = @_;
	if($e->type == SDL_ACTIVEEVENT) {
		if($e->active_state & SDL_APPMOUSEFOCUS) {
			$M{scene}->cursor->hide = !$e->active_gain;
		}
		if($e->active_state & (SDL_APPINPUTFOCUS)) {
			return 1 if $e->active_gain;
			$App->pause(\&window);
		}
	}
	$M{fullscreen};
}

sub mouse {
	my ($e) = @_;
	if($e->type == SDL_MOUSEBUTTONDOWN) {
		$M{mouse}[2] = $e->button_button & (SDL_BUTTON_LEFT | SDL_BUTTON_MIDDLE | SDL_BUTTON_RIGHT);
		
	}
	elsif($e->type == SDL_MOUSEMOTION) {
		$M{mouse}[0] = $e->motion_x;
		$M{mouse}[1] = $e->motion_y;
	}
}

$App->add_event_handler(\&stop);
$App->add_event_handler(\&window);
$App->add_event_handler(\&mouse);

#####################################MOVE####################################

sub move_sprites {
	return unless $_[0];
	for(@{$M{scene}->holders}, $M{scene}->cursor) {
		my $frame = $_->sprite->frame + $_[0];
		if($frame >= @{$_->sprite->sequence}) {
			$frame = 0;
		}
		$_->sprite->frame = $frame;
		$_->sprite->events_sequence->($_->sprite, int $frame, $frame == 0, $_[0]);
	}
}

sub move_klaymen {
	if($M{scene}->klaymen) {
		if($Klaymen->sprite_name ~~ [qw/idle/]) {
			if(defined $M{blink_in}) {
				delete $M{blink};
				$M{blink_in} -= $_[0];
				if($M{blink_in} <= 0) {
					$M{blink} = 1;
					delete $M{blink_in};
				}
			}
			$M{blink_in} = int rand(40) + 30 unless defined $M{blink_in};
		}
		else {
			delete $M{blink_in};
			delete $M{blink};
		}
		
		
		
	}
}

$App->add_move_handler(\&move_sprites);
$App->add_move_handler(\&move_klaymen);

#####################################SHOW####################################

sub show_sprites {
	for(@{$M{scene}->holders}) {
		$_->sprite->show;
	}
	$M{scene}->cursor->sprite->show;
}

$App->add_show_handler(\&show_sprites);

$App->add_show_handler(sub { $App->flip });

$App->add_show_handler(sub { delete $M{mouse}[2]});

1;
