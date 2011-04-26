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
use File::Spec;

our $Scene;
our $Folder;
our $Fullscreen;
our $Cheat;
our $Remainder;
our $FastForward;
BEGIN {
	$Folder //= File::ShareDir::dist_dir('Games-Neverhood');
	$Fullscreen = !$ARGV[0];
	$Cheat = '';
	$Remainder = 0;
	$FastForward = 0;
}

use Games::Neverhood::Cursor;
our $Cursor;
use Games::Neverhood::Klaymen;
our $Klaymen;

our $App;
sub init {
	$ENV{SDL_VIDEO_CENTERED} = 1;
	$App = SDLx::App->new(
		w => 640,
		h => 480,
		d => 32,
		title => 'The Neverhood',
		# $Fullscreen ? () : (min_t => 0),
		fullscreen => $Fullscreen,
		flags =>
#			SDL_ASYNCBLIT |
#			SDL_SWSURFACE |
			SDL_HWSURFACE |

#			SDL_ANYFORMAT  |
			SDL_HWPALETTE  |
			SDL_HWACCEL    |
			SDL_DOUBLEBUF  |
			SDL_NOFRAME    |
#			SDL_PREALLOC   |
			0,
		event_handlers => [
			\&window,
			\&mouse,
			\&keyboard,
			\&pause,
		],
		move_handlers => [
			\&move_sprites,
			\&move_scene,
			\&move_klaymen,
		],
		show_handlers => [
			\&show_sprites,
			sub{$App->flip},
		],
	);
	SDL::Mouse::show_cursor(SDL_DISABLE);
	SDL::Video::wm_set_icon(SDLx::Surface->load( File::Spec->catfile($Folder, 'misc', 'icon.png') ));
	
	use Games::Neverhood::Scene::Nursery::One '';
	$Scene = $Games::Neverhood::Scene::Nursery::One;
	$Scene->call($Scene->setup, $Scene, {
		klaymen => $Klaymen,
	});
	$App->dt(1 / $Scene->fps);

	$App->run;
}

#####################################EVENT###################################

sub window {
	my ($e) = @_;
	if($e->type == SDL_QUIT) {
		$App->stop;
	}
	elsif($e->type == SDL_ACTIVEEVENT) {
		if($e->active_state & SDL_APPMOUSEFOCUS) {
			$Cursor->hide(!$e->active_gain); #cursor in window
		}
		if($e->active_state & SDL_APPINPUTFOCUS) {
			return 1 if $e->active_gain;
			$App->pause(\&window);
		}
	}
	$Fullscreen;
}

sub mouse {
	my ($e) = @_;
	if($e->type == SDL_MOUSEBUTTONDOWN and $e->button_button & (SDL_BUTTON_LEFT | SDL_BUTTON_MIDDLE | SDL_BUTTON_RIGHT) and !$Cursor->hide) {
		my @pos = ($e->button_x, $e->button_y);
		my (undef, $event) = $Scene->cursors->(@pos);
		$event = 'click' unless defined $event;
		$Cursor->clicked([@pos, $event]);
	}
	elsif($e->type == SDL_MOUSEMOTION) {
		my @pos = ($e->motion_x, $e->motion_y);
		my ($sprite) = $Scene->cursors->(@pos);
		$sprite = 'click' unless defined $sprite;
		$Cursor->sprite($sprite);
		$Cursor->pos(\@pos);
	}
}

sub keyboard {
	my ($e) = @_;
	if($e->type == SDL_KEYDOWN) {
		my $name = SDL::Events::get_key_name($e->key_sym);
		given($name) {
			when('escape') {
				$App->stop;
			}
			when('space') {

			}
			when('return') {
				if($Cheat eq 'fastforward') {
					$FastForward = !$FastForward;
					$App->dt($App->dt / 100);
				}
				elsif($Cheat eq 'happybirthdayklaymen') {
					if(
						$Scene == $Games::Neverhood::Scene::Nursery1 or
						$Scene == $Games::Neverhood::Scene::Nursery1OutWindow
					) {

					}
				}
				$Cheat = '';
			}
			when(/^[a-z]$/) {
				$Cheat .= $name;
				$Cheat = '-' if length $Cheat > 19;
			}
			when(/ctrl$/) {
				$ARGV[1] = !$ARGV[1];
				$App->draw_rect([], 0) if $ARGV[1];
			}
		}
	}
}

sub pause {
	my ($e) = @_;
	if($e->type == SDL_KEYDOWN and $e->key_sym == SDLK_LALT or $e->key_sym == SDLK_RALT) {
		$App->pause(sub{1});
	}
}

#####################################MOVE####################################

sub move_sprites {
	my ($step) = @_;
	return unless $step;
	$Remainder += $step;
	$Remainder -= int $Remainder;
	for my $sprite (@{$Scene->sprites}, $Cursor) {
		next unless $sprite;
		my $frame = $sprite->frame + $step;
		if(int $frame eq $sprite->to_frame or $sprite->to_frame eq 'end') {
			$sprite->to_frame(-1, int $frame);
		}
		else {
			$sprite->to_frame((int $frame) x 2);
		}
		if($frame >= @{$sprite->this_sequence}) {
			$frame = $Remainder;
			$sprite->to_frame(0, 'end');
		}
		$sprite->frame = $frame;
		my $arg = {
			step    => $step,
			klaymen => $Klaymen,
			scene   => $Scene,
		};
		for(my $i = 0; $i < @{$sprite->events_sequence}; $i++) {
			my $condition = $sprite->events_sequence->[$i++];
			if(
				ref $condition and ref $condition eq 'CODE' and $Scene->call($condition, $sprite, $arg)
				or !ref $condition and (
				$condition eq 'true'
				or $sprite->get(undef, 'end') )
			) {
				$Scene->call($sprite->events_sequence->[$i], $sprite, $arg);
			}
		}
	}
}

sub move_scene {
	return unless my $click = $Cursor->clicked;
	my $event = $click->[2];
	die "click fail\n", Dumper $click unless defined $event;
	my $arg = {
		click   => $click,
		klaymen => $Klaymen,
		scene   => $Scene,
	};
	for my $sprite (grep ref $_->$event, @{$Scene->sprites}) {
		for(my $i = 0; $i < @{$sprite->$event}; $i++) {
			my $condition = $sprite->$event->[$i++];
			if(
				ref $condition and ( ref $condition eq 'ARRAY' and $sprite->rect(@$condition)
				or ref $condition eq 'CODE' and $Scene->call($condition, $sprite, $arg) )
				or !ref $condition and ( $condition eq 'true'
				or $Klaymen->sprite =~ /$condition/ )
			) {
				my $return = $Scene->call($sprite->$event->[$i], $sprite, $arg);
				$return = '' unless defined $return;
				unless($return eq 'no') {
					$Scene->delete_clicked unless $return eq 'not_yet';
					return;
				}
			}
		}
	}
	if($Scene->klaymen and $Klaymen->sprite =~ /^idle/) {
		my $bound;
		if(
			$bound = $Scene->bounds and
			$bound->[0] <= $click->[0] and $bound->[1] <= $click->[1]
			and $bound->[2] >= $click->[0] and $bound->[3] >= $click->[1]

			and !$Klaymen->sprite eq 'idle' || ($click->[0] < $Klaymen->pos->[0] - 38 || $click->[0] > $Klaymen->pos->[0] + 38)
		) {
			$Klaymen->move_to(to => $click->[0]);
		}
		$Scene->delete_clicked;
		return;
	}
}

sub move_klaymen {
	return unless $Scene->klaymen;
	if($Klaymen->sprite eq 'idle') {
		if(defined $Klaymen->blink_in) {
			$Klaymen->blink_in($Klaymen->blink_in - $_[0]);
			$Klaymen->random_in($Klaymen->random_in - $_[0]);
			if($Klaymen->blink_in <= 0) {
				$Klaymen->sequence(1);
				$Klaymen->blink_in(undef);
			}
			if($Klaymen->random_in <= 0) {
				$Klaymen->sprite('idle_random_' . int rand 5);
				$Klaymen->random_in(undef);
			}
		}
		$Klaymen->blink_in(int rand(40) + 30) unless defined $Klaymen->blink_in;
		$Klaymen->random_in(int rand(40) + 600) unless defined $Klaymen->random_in;
	}
	else {
		$Klaymen->blink_in(undef);
		$Klaymen->random_in(undef);
	}
	if(my $move = $Klaymen->moving_to) {
		my ($to, @type);
		{
			no warnings 'uninitialized';
			my $min = 1e100;
			for(qw/left right to/) {
				my $v;
				if($_ eq 'to') {
					$v = $move->{to};
				}
				else {
					(undef, $v) = each @{$move->{$_}[0]};
				}
				next unless defined $v;
				my $new = abs($v - $Klaymen->pos->[0]);
				if($new < $min) {
					($min, $to) = ($new, $v);
					@type = $_;
				}
				elsif($new == $min and $to == $v) {
					push @type, $_;
				}
				redo unless $_ eq 'to';
			}
		}
		;#( $maximum, $minimum )
		my $adjust = (5,  );
		my @shuffle = (20, $adjust);
		my @slide = (100, $shuffle[0]);
		my @walk_stop = (40, $shuffle[0]);
		my $further = abs($to - $Klaymen->pos->[0]);
		my $dir = $to <=> $Klaymen->pos->[0];
		my $left = $dir - 1;
		
		if($further) {
			if($Klaymen->sprite eq 'idle') {
				if($further <= $adjust) {
					$Klaymen->flip($left);
					my $speed = 2 * $_[0];
					$Klaymen->pos->[0] += $speed;
					$Klaymen->pos->[0] = $to if $further <= $speed;
				}
				elsif($further <= $shuffle[0]) {
					$Klaymen->set('idle_shuffle');
				}
			}
		}
		else {
			#set or do
		}
		# if($Klaymen->pos->[0] == $to) {
			# if($Klaymen->get('idle')) {
				# if(defined $move->{do}) {
					# $M{scene}->call(
						# $move->{do}, $move->{sprite},
						# {
							# klaymen => $Klaymen,
							# scene => $M{scene},
							# click => $M{click}
						# }
					# );
				# }
				# if(defined $move->{set}) {
					# $Klaymen->set(@{$move->{set}});
				# }
				# elsif(!defined $move->{do}) {
					# $Klaymen->set('idle');
				# }
				# delete $M{move_to};
			# }
		# }
		# elsif($Klaymen->flip == ($Klaymen->pos->[0] > $to ? 1 : 0)) {
			# if($Klaymen->get('idle_walk')) {
				# if($further >= $walk_stop[0]) {
					# if($Klaymen->to_frame > 0 and not $Klaymen->to_frame % 2) {
						# $Klaymen->pos->[0] += 10 * $dir;
					# }
					# elsif($Klaymen->to_frame eq 'end') {
						# $Klaymen->pos->[0] += 20 * $dir;
					# }
				# }
				# elsif(1) { }
			# }
			# elsif($Klaymen->get('idle_walk_start')) {
			
			# }
			# elsif($Klaymen->get('idle_walk_end')) {
			
			# }
			# elsif($Klaymen->get('idle_shuffle')) {
			
			# }
			# elsif($Klaymen->get('idle_shuffle_end')) {
			
			# }
			# elsif($Klaymen->get('idle_slide')) {
			
			# }
			# elsif($Klaymen->get('idle_slide_end')) {
			
			# }
		# }
		# elsif($further <= $adjust) {
			# my $speed = 5;
			# $Klaymen->flip($left);
			# $Klaymen->pos->[0] += $speed * $dir * $_[0];
			# $Klaymen->pos->[0] = $to if $further <= $speed * $_[0];
		# }
		# if($to > $Klaymen->pos->[0]) {
			# $Klaymen->flip(0);
		# }
		# elsif($to < $Klaymen->pos->[0]) {
			# $Klaymen->flip(1);
		# }
	}
}

#####################################SHOW####################################

sub show_sprites {
	for(@{$Scene->sprites}, $Cursor) {
		$_->show unless $ARGV[1] and $_ != $Klaymen and $_ != $Cursor;
	}
}

1;
