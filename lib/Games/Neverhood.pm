# the game object -- subclass of SDLx::App with inside-out game class
use 5.01;
use strict;
use warnings;
package Games::Neverhood;

our $VERSION;
BEGIN { $VERSION = 0.004 }

use SDL;
use Games::Neverhood::App;
use SDL::Video;
use SDL::Color;
use SDL::Events;
# use SDLx::Mixer;
use File::Spec;

use parent 'Exporter';
our @EXPORT_OK;
BEGIN { @EXPORT_OK = qw/$Remainder $Debug $FPSLimit $Fullscreen $NoFrame $ShareDir $StartUnset $StartSet/ }

use overload
	# string overload to return ref $self, but without Games::Neverhood:: prefix
	'""'   => sub { ref($_[0]) =~ /^Games::Neverhood::(.*)/ and return $1; '' },
	'0+'   => sub { no overloading; $_[0] },
	'fallback' => 1,
;

# keeping track of the frame remainder of stepping
# TODO: keep track of this in GG
our $Remainder;

# globals from bin/nhc
our ($Debug, $FPSLimit, $Fullscreen, $NoFrame, $ShareDir, $StartSetName, $StartUnsetName);
BEGIN {
	$Remainder = 0;
#	$Debug;
	$FPSLimit       //= 60;
	$Fullscreen     //= 1;
	$NoFrame        //= 1;
	$ShareDir       //= do { require File::ShareDir; File::ShareDir::dist_dir('Games-Neverhood') };
	$StartSetName   //= 'Scene::Nursery::One';
	$StartUnsetName //= $Games::Neverhood::StartSetName;
}

# game globals
use Games::Neverhood::GG;
sub GG { state $GG = Games::Neverhood::GG->new }

# global sprites
use Games::Neverhood::Sprite::Klaymen;
use Games::Neverhood::Sprite::Cursor;
sub klaymen { state $klaymen = Games::Neverhood::Sprite::Klaymen->new }
sub cursor  { state $cursor  = Games::Neverhood::Sprite::Cursor ->new }

# game objects
use Games::Neverhood::Scene::Nursery::One;
use Games::Neverhood::Scene::Test;

# the SDLx::App
sub app {
	state $app = do {
		my ($event_window_pause, $event_pause);
		$event_window_pause = sub {
			# pause when the app loses focus
			my ($e, $app) = @_;
			if($e->type == SDL_ACTIVEEVENT) {
				if($e->active_state & SDL_APPINPUTFOCUS) {
					return 1 if $e->active_gain;
					$app->pause($event_window_pause);
				}
			}
			# if we're fullscreen we should unpause no matter what event we get
			$Fullscreen;
		};
		$event_pause = sub {
			# toggle pause when either alt is pressed
			my ($e, $app) = @_;
			state $lalt;
			state $ralt;
			if($e->type == SDL_KEYDOWN) {
				if($e->key_sym == SDLK_LALT) {
					$lalt = 1;
				}
				elsif($e->key_sym == SDLK_RALT) {
					$ralt = 1;
				}
				else {
					undef $lalt;
					undef $ralt;
				}
			}
			elsif($e->type == SDL_KEYUP and $e->key_sym == SDLK_LALT && $lalt || $e->key_sym == SDLK_RALT && $ralt) {
				undef($e->key_sym == SDLK_LALT ? $lalt : $ralt);
				return 1 if $app->paused;
				$app->pause($event_pause);
			}
			return;
		};

		Games::Neverhood::App->new(
			title      => 'The Neverhood',
			width      => 640,
			height     => 480,
			depth      => 16,
			min_t      => $FPSLimit && 1 / $FPSLimit,
			eoq        => 1,
			init       => ['video', 'audio'],
			no_cursor  => 1,
			centered   => 1,
			flags      => 0,
			fullscreen => $Fullscreen,
			no_frame   => $NoFrame,
			hw_surface => 1, double_buf => 1,
	#		sw_surface => 1,
	#		any_format => 1,
	#		async_blit => 1,
	#		hw_palette => 1,

			icon => do {
				my $icon;
				if($icon = SDL::Video::load_BMP(File::Spec->catfile($ShareDir, 'icon.bmp'))) {
					SDL::Video::set_color_key($icon, SDL_SRCCOLORKEY, SDL::Color->new(255, 255, 255));
				}
				$icon;
			},

			event_handlers => [

				$event_window_pause,
				$event_pause,
				sub{$;->event(@_)},
			],
			move_handlers => [
				sub{$;->move(@_)},
			],
			show_handlers => [
				sub{SDL::Video::fill_rect($_[1], SDL::Rect->new(0, 0, 640, 480), 0)},
				sub{$;->show(@_)},
				sub{$_[1]->flip},
				sub {
					my (undef, $app) = @_;
					return unless defined(my $set_name = $;->set);
					$;->set(undef);
					my $unset_name = "$;";

					$;->on_destroy($set_name);
					$;->cursor->clicked(undef);
					undef $;;

					# inside this, $; gets set to the new object
					"Games::Neverhood::$set_name"->new($unset_name);

					$app->dt(1 / $;->fps);
				},
			],
		);
	};
}

# SDLx::Mixer::init(
	# frequency => 22050,
	# channels => 1,
	# chunk_size => 1024,
	# support => ['ogg'],
	# streams => 8,
# );

sub new {
	# TODO: what else should go here? Is this redundant?
	my ($class) = @_;
	$; = bless {}, ref $class || $class;
}

sub set {
	if(@_ > 1) { $_[0]->{set} = $_[1]; return $_[0]; }
	$_[0]->{set};
}

# inside this, $; gets set to the new object
"Games::Neverhood::$StartSetName"->new($StartUnsetName);
$;->app->dt(1 / $;->fps);

# you're NOT allowed to use $; to refer to the current app if you're a game class, okay? PROMISE?
# no seriously, I mean it...
# we're going on the assumption that if you're a sprite or something, you're only being asked to do something because you're in the current app
# no two apps should ever access one another
# use the assumption, don't abuse the assumption

###############################################################################
# methods to be overloaded by Games::Neverhood::Scene and such

sub event {}
sub move {}
sub show {}

1;
