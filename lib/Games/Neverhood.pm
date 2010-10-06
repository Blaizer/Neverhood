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

our %M;
BEGIN {
	
	%M = (
		defined $M{folder} ? () : (folder => File::ShareDir::dist_dir('Games-Neverhood')),
		%M,
		fullscreen => $ARGV[0] ? 0 : SDL_FULLSCREEN,
		mouse      => [],
		click      => [],
	);
}

our $App;
sub init {
	$ENV{SDL_VIDEO_CENTERED} = 1;
	$App = SDLx::App->new(
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

	$Games::Neverhood::Scene::Nursery1->set;

	$App->add_event_handler(\&stop);
	$App->add_event_handler(\&window);
	$App->add_event_handler(\&mouse);
	$App->add_event_handler(\&keyboard);

	$App->add_move_handler(\&move_sprites);
	$App->add_move_handler(\&move_scene);
	$App->add_move_handler(\&move_klaymen);

	$App->add_show_handler(\&show_sprites);
	$App->add_show_handler(sub{$App->flip});

	$App->run;
}

use Games::Neverhood::Scene;
use Games::Neverhood::Holder;
use Games::Neverhood::Sprite;

use Games::Neverhood::Cursor;
our $Cursor;
use Games::Neverhood::Klaymen;
our $Klaymen;

use Games::Neverhood::Scene::Nursery;

#####################################EVENT###################################

sub stop {
	my ($e) = @_;
	$App->stop if $e->type == SDL_QUIT;
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
		my @pos = ($e->button_x, $e->button_y);
		$M{scene}->cursor(@pos);
		$M{click}[defined $M{click}[0] ? 1 : 0]
			= [@pos, $M{event}] if $e->button_button & (SDL_BUTTON_LEFT | SDL_BUTTON_MIDDLE | SDL_BUTTON_RIGHT);
	}
	elsif($e->type == SDL_MOUSEMOTION) {
		$M{mouse}[0] = $e->motion_x;
		$M{mouse}[1] = $e->motion_y;
	}
}

sub keyboard {
	my ($e) = @_;
	if($e->type == SDL_KEYDOWN) {
		my $name = SDL::Events::get_key_name($e->key_sym);
		given($name) {
			when('escape') {
				$e->type(SDL_QUIT);
				&stop;
			}
			when('space') {

			}
			when('enter') {
				given($M{cheat}) {
					when('fastforward') {
						$M{fast_forward} = !$M{fast_forward};
						$M{scene}->dt *= 3;
					}
					when('happybirthdayklaymen') {
						if(
							$M{scene} eq $Games::Neverhood::Scene::Nursery1 or
							$M{scene} eq $Games::Neverhood::Scene::Nursery1OutWindow
						) {

						}
					}
					delete $M{cheat}
				}
			}
			when(/[a-z]/) {
				$M{cheat} .= $name;
				delete $M{cheat} if length $M{cheat} > 20;
			}
		}
	}
}

#####################################MOVE####################################

sub move_sprites {
	return unless $_[0];
	for(@{$M{scene}->holders}, $M{scene}->cursor) {
		my $frame = $_->sprite->frame + $_[0];
		if($frame >= @{$_->sprite->sequence}) {
			$frame = 0;
		}
		$_->sprite->frame = $frame;
		$_->sprite->events_sequence->(
			$_->sprite,
			{
				frame   => int $frame,
				end     => $frame == 0,
				step    => $_[0],
				klaymen => $Klaymen,
				scene   => $M{scene},
			}
		);
	}
}

sub move_scene {
	if(@{$M{click}}) {
		my $return = $M{scene}->move($M{click}, $Klaymen);
		if(defined $return and $return eq '_') {
			my $click = shift @{$M{click}};
			my $bound = $M{scene}->bounds;
			if(
				$bound->[0] <= $click->[0] and $bound->[1] <= $click->[1]
				and $bound->[2] >= $click->[0] and $bound->[2] >= $click->[1]
			) {
				$M{scene}->move_to($click->[0], undef, 1);
			}
		}
	}
}

sub move_klaymen {
	my ($step) = @_;
	if($M{scene}->klaymen) {
		if($Klaymen->sprite_name ~~ [qw/idle/]) {
			if(defined $M{blink_in}) {
				$M{blink_in} -= $_[0];
				$M{random_in} -= $_[0];
				if($M{blink_in} <= 0) {
					$Klaymen->sprite->sequence_num = 1;
					delete $M{blink_in};
				}
				if($M{random_in} <= 0) {
					$Klaymen->sprite_name = 'idle_random_' . int rand(5);
					$Klaymen->sprite->frame = 0;
					$Klaymen->sprite->sequence_num = 0;
					delete $M{random_in};
					delete $M{blink_in};
				}
			}
			$M{blink_in} = int rand(40) + 30 unless defined $M{blink_in};
			$M{random_in} = int rand(40) + 600 unless defined $M{random_in} 
		}
		else {
			delete $M{blink_in};
		}
		if($Klaymen->sprite_name =~ /^idle/ and defined $M{move_to} and @{$M{move_to}}) {
			my $speed = 6 * $step;
			$Klaymen->sprite_name = 'idle';
			delete $M{blink_in};
			delete $M{random_in};
			if($M{move_to}[0] > $Klaymen->pos->[0]) {
				$Klaymen->sprite->flip(0);
				$Klaymen->pos->[0] += $speed;
				$Klaymen->pos->[0] = $M{move_to}[0] if $Klaymen->pos->[0] > $M{move_to}[0];
			}
			elsif($M{move_to}[0] < $Klaymen->pos->[0]) {
				$Klaymen->sprite->flip(1);
				$Klaymen->pos->[0] -= $speed;
				$Klaymen->pos->[0] = $M{move_to}[0] if $Klaymen->pos->[0] < $M{move_to}[0];
			}
			if($Klaymen->pos->[0] == $M{move_to}[0]) {
				if(defined $M{move_to}[1]) {
					$M{scene}->event($M{click}, $Klaymen, $M{move_to}[1])
				}
				delete $M{move_to};
			}
		}
	}
}

#####################################SHOW####################################

sub show_sprites {
	for(@{$M{scene}->holders}) {
		$_->sprite->show;
	}
	if($ARGV[1]) {
		for(values %{$M{scene}->event_rects}) {
			if($_->[2] and $_->[3]) {
				my $rect = SDLx::Surface->new(w => $_->[2], h => $_->[3], d => 32, color => 0xFF000000);
				SDL::Video::set_alpha($rect, 0, 128) and die SDL::get_error;
				$rect->blit($App, [0, 0, $_->[2], $_->[3]], [$_->[0], $_->[1]]);
			}
		}
	}
	$M{scene}->cursor->sprite->show;
}

1;
