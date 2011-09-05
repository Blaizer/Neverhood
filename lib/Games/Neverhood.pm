# the game object -- subclass of SDLx::App with inside-out game class
package Games::Neverhood;
use 5.01;
use strict;
use warnings;
our $VERSION = 0.004;

use parent qw/SDLx::App/;

use SDL;
use SDL::Video;
use SDL::Color;
# use SDLx::Mixer;
use SDL::Events;
use File::Spec;

use parent 'Exporter';
our @EXPORT_OK;
BEGIN { @EXPORT_OK = qw/$Debug $FPSLimit $Fullscreen $NoFrame $ShareDir $StartUnset $StartSet/ }

# the current game object
my $Game;
BEGIN {
	# quick way of giving the set method an unset object it can use
	no strict 'refs';
	my $unset = "Games::Neverhood::$StartUnset";
	@{"$unset::ISA"} = 'Games::Neverhood';

	$unset->new->set($StartSet);
	$Game->set;
}

use overload
	# hash overload to use the SDLx::App as if it was the $Game object
	'%{}' => sub { $Game },

	# string overload to return ref $self, but without Games::Neverhood:: prefix
	'""'   => sub { ref($_[0]) =~ /^Games::Neverhood::(.*)/ and return $1; '' },
	'0+'   => sub { no overloading; $_[0] },

	'fallback' => 1,
;

# globals from bin/nhc
our ($Debug, $FPSLimit, $Fullscreen, $NoFrame, $ShareDir, $StartUnset, $StartSet);
BEGIN {
#	$Debug;
	$FPSLimit   //= 60;
	$Fullscreen //= 1;
#	$NoFrame;
	$ShareDir   //= do { require File::ShareDir; File::ShareDir::dist_dir('Games-Neverhood') };
	$StartSet   //= 'Scene::Nursery::One';
	$StartUnset //= $Games::Neverhood::StartSet;
}

use Games::Neverhood::Sprite::Klaymen;
use Games::Neverhood::Sprite::Cursor;

my $Klaymen = Games::Neverhood::Sprite::Klaymen->new;
my $Cursor  = Games::Neverhood::Sprite::Cursor->new;

sub klaymen { $Klaymen }
sub cursor { $Cursor }

# SDLx::Mixer::init(
	# frequency => 22050,
	# channels => 1,
	# chunk_size => 1024,
	# support => ['ogg'],
	# streams => 8,
# );

sub set {
	state $_set;
	
	my $self = shift;
	if(@_) {
		$_set = shift;
		return $self;
	}
	return $self unless defined $_set;

	my $set_name = join "::", "Games::Neverhood", $_set;
	undef $_set;

	# set -- call constructor
	my $set = $set_name->new($self);
	
	# unset -- call destructor
	undef $self;

	# put set in $Game (destructor actually happens here ;)
	$set->game($set);

	$set->dt(1 / $set->fps);
	
	# $set->cursor->sprite($set->cursor_sprite);
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
			# sub{$Game->event(@_)},
		],
		move_handlers => [
			# sub{$Game->move(@_)}
		],
		show_handlers => [
			# sub{$Game->show(@_)},
			sub{$App->flip},
			# sub{$Game->set},
		],
	);
}

###############################################################################

sub GG { $GG };

# Game Globals
my $GG = {
	# 2, 1, 4, 5, 3, 11, 8, 6, 7, 9, 10, 17, 16, 18, 19, 20, 15, 14, 13, 12
	# $nursery_1_window_open -- until jump down in nursery_2
	# $flytrap_place         -- only while in mail room, also remember if it has grabbed ring
	# %mail_done             -- from when the flytrap grabs the ring until willie dies
		# flytrap     -- when the flytrap grabs the ring
		# music_box   -- when the musicbox c starts
		# boom_sticks -- when the boom sticks are solved
		# weasel      -- when the weasel dying c starts
		# h           -- when the H is solved
		# beaker      -- when the beaker is picked up
		# foghorn_1   -- when the foghorn button thru the spikes is pressed
		# drink       -- when you drink from the foutain
		# notes       -- when the pipes are solved and the button is pressed
		# foghorn_2   -- when the foghorn button next to frenchie is pressed
		# foghorn_3   -- when the foghorn button in circles is pressed
		# locks       -- when the 3 locks are unlocked
		# drain_lake  -- when the cannon is shot to drain the lake
		# into_lake   -- when you go down the stairs
		# radio_on    -- when you go into the radio room with it on
		# radio_song  -- when you enter the lab
		# fast_door   -- when you get past the fast door
		# bear_lure   -- when you swing the bear around
		# cannon_1    -- when cannon code 1 is entered
		# bil_boom    -- when bil is shot
		# bil_sense   -- when willie dies

	# $spam_number -- as soon as spam is seen, undef when back to first and when willie dies
	# %disk        -- as soon as a disk is picked up
		# shack
		# h_house_1
		# h_house_2
		# thru_spikes
		# hall_end
		# note_house_1
		# note_house_2
		# note_house_3
		# radio_place
		# lab_middle_floor
		# lab_top_floor
		# whale_house_1
		# whale_house_2
		# trap_room
		# fun_house_left_1
		# fun_house_left_2
		# fun_house_right
		# willies_house
		# castle_key_room
		# castle_top_floor

	# @dummy_places -- init with (0, 1, 0, 2, 1, 1) when enter shack, undef when solved
		  # 1     2636
		# 2 3 4   5124
		 # 5 6    1345
	# $match            -- 1 when match is picked up, 2 when dummy is lit
	# $water_on         -- when the water in t2 is turned on, undef when turned off
	# @foghorn          -- when each foghorn button is pressed, undef when pressed again
	# @h                -- when the h house is entered, undef when solved h
	# $h_blank_top      -- when solved h, 1 for blank piece in h at top, 0 for bottom
	# $spikes_open      -- when spikes are open, undef when closed
	# $said_knock_knock -- when the dude in the box says knock knock, undef when foghorn pressed or disk taken
	# @cannon_code_1    -- when the first cannon code is changed, undef when back to original, empty list when solved
	# @cannon_code_2    -- ditto
	# @bridge_puzzle    -- when a bridge puzzle piece is moved, undef when none are on stack and when gone into lake
	# $bridge_down      -- when the bridge is moved down, undef when down the bridge and when moved up, redef when back up bridge
	# $raido_song       -- when either radio is seen
	# @safety_beakers   -- when either the safety beakers are seen or the safety lab is used
	# @beakers          -- when either the lake wall beakers are seen or the lab is used
	# @crystals         -- when the shrinking machine is used, roygbp, empty list when solved
};

###############################################################################

# stop on quit event or alt-f4
sub event_quit {
	my ($e) = @_;
	if(
		$e->type == SDL_QUIT
		or
		$e->type == SDL_KEYDOWN and $e->key_sym == SDLK_F4
		and $e->key_mod & KMOD_ALT and not $e->key_mod & (KMOD_CTRL | KMOD_SHIFT | KMOD_META)
	) {
		$App->stop;
		return 1;
	}
	return;
}

# pause when the app loses focus
sub event_window {
	my ($e) = @_;
	if($e->type == SDL_ACTIVEEVENT) {
		if($e->active_state & SDL_APPINPUTFOCUS) {
			return 1 if $e->active_gain;
			pause(\&event_window);
		}
	}
	# if we're fullscreen we should unpause no matter what event we get
	$Fullscreen;
}

# toggle pause when either alt is pressed
sub event_pause {
	my ($e) = @_;
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
		return 1 if $App->paused;
		pause(\&event_pause);
	}
	return;
}

# extra sub for pause to go through
# for pre and post-pause and quitting while paused
sub pause {
	my ($callback) = @_;
	# SDL::Mixer::Music::pause_music;
	# SDL::Mixer::Channels::pause(-1);

	$App->pause(sub {
		&$callback or &event_quit;
	});

	# SDL::Mixer::Music::resume_music;
	# SDL::Mixer::Channels::resume(-1);
}

1;
