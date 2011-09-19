# the game object -- subclass of SDLx::App with inside-out game class
use 5.01;
use strict;
use warnings;
package Games::Neverhood;

our $VERSION;
BEGIN { $VERSION = 0.004 }

use parent qw/SDLx::App/;

use SDL;
use SDL::Video;
use SDL::Color;
use SDL::Events;
# use SDLx::Mixer;
use File::Spec;

use parent 'Exporter';
our @EXPORT_OK;
BEGIN { @EXPORT_OK = qw/$Remainder $Debug $FPSLimit $Fullscreen $NoFrame $ShareDir $StartUnset $StartSet/ }

my $Game;

use overload
	# hash overload to use the SDLx::App as if it was the $Game object
	'%{}' => sub { $Game },

	# string overload to return ref $self, but without Games::Neverhood:: prefix
	'""'   => sub { ref($_[0]) =~ /^Games::Neverhood::(.*)/ and return $1; '' },
	'0+'   => sub { no overloading; $_[0] },

	'fallback' => 1,
;

# keeping track of the frame remainder of stepping
our $Remainder;

# globals from bin/nhc
our ($Debug, $FPSLimit, $Fullscreen, $NoFrame, $ShareDir, $StartNew, $StartDestroy);
BEGIN {
	$Remainder = 0;
#	$Debug;
	$FPSLimit     //= 60;
	$Fullscreen   //= 1;
	$NoFrame      //= 1;
	$ShareDir     //= do { require File::ShareDir; File::ShareDir::dist_dir('Games-Neverhood') };
	$StartNew     //= 'Scene::Nursery::One';
	$StartDestroy //= $Games::Neverhood::StartNew;
}

# global sprites
use Games::Neverhood::Sprite::Klaymen;
use Games::Neverhood::Sprite::Cursor;
my ($Klaymen, $Cursor);
BEGIN {
	$Klaymen = Games::Neverhood::Sprite::Klaymen->new;
	$Cursor  = Games::Neverhood::Sprite::Cursor->new;
}
sub klaymen { $Klaymen }
sub cursor { $Cursor }

# all game scenes
use Games::Neverhood::Scene::Nursery::One;
use Games::Neverhood::Scene::Test;

# SDLx::Mixer::init(
	# frequency => 22050,
	# channels => 1,
	# chunk_size => 1024,
	# support => ['ogg'],
	# streams => 8,
# );

# making an unset object for set to use
my $unset = "Games::Neverhood::$StartDestroy";
$unset->new->set($StartNew);
$Game->set;

sub set {
	state $_set;
	
	my ($self, $set) = @_;
	if(@_ > 1) {
		$self->{set} = $set;
		return $self;
	}
	return $self unless defined $self->{set};

	my $set_name = join "::", "Games::Neverhood", $_set;
	undef $_set;

	# set -- call constructor
	my $set = $set_name->new($self);
	
	# unset -- call destructor
	undef $self;

	#destructor actually happens here ;)
	$Game = $set;

	$set->dt(1 / $set->fps);
	
	$set->cursor->sequence($set->cursor_sequence);
	$set;
}

sub new {
	my $self = $_[0]->SUPER::new(
		title      => 'The Neverhood',
		width      => 640,
		height     => 480,
		depth      => 8,
		min_t      => $FPSLimit && 1 / $FPSLimit,
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
			\&event_quit,
			\&event_window,
			\&event_pause,
			sub{$_[1]->event(@_)},
		],
		move_handlers => [
			sub{$_[1]->move(@_)}
		],
		show_handlers => [
			sub{$_[1]->show(@_)},
			sub{$_[1]->flip},
			sub{$_[1]->set},
		],
	);
}

###############################################################################
# methods to be overloaded by Games::Neverhood::Scene and such

sub sprites {}
sub frame {}

sub sprites_list {}
sub all_dir {}
sub fps {}
sub cursor_type {}
sub klaymen_move_bounds {}
sub music {}

sub event {}
sub move {}
sub show {}

sub on_move {}
sub on_show {}
sub on_space {}
sub on_click {}
sub on_out {}
sub on_left {}
sub on_right {}
sub on_up {}
sub on_down {}

###############################################################################
# these aren't methods at all, just some event handler stuff

# stop on quit event or alt-f4
sub event_quit {
	my ($e, $self) = @_;
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

# pause when the app loses focus
sub event_window {
	my ($e, $self) = @_;
	if($e->type == SDL_ACTIVEEVENT) {
		if($e->active_state & SDL_APPINPUTFOCUS) {
			return 1 if $e->active_gain;
			$self->pause(\&event_window);
		}
	}
	# if we're fullscreen we should unpause no matter what event we get
	$Fullscreen;
}

# toggle pause when either alt is pressed
sub event_pause {
	my ($e, $self) = @_;
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
		return 1 if $self->paused;
		$self->pause(\&event_pause);
	}
	return;
}

# overloaded SDLx::App pause method for pre and post pause
sub pause {
	my ($self, $callback) = @_;
	# SDL::Mixer::Music::pause_music;
	# SDL::Mixer::Channels::pause(-1);

	$self->SUPER::pause($callback);

	# SDL::Mixer::Music::resume_music;
	# SDL::Mixer::Channels::resume(-1);
}

1;
