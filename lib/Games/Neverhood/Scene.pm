package Games::Neverhood::Scene;
use 5.01;
use strict;
use warnings;

use SDL::Events;

use parent
	'Games::Neverhood::GameMode',
	'Exporter',
;

use Scalar::Util ();

use Data::Dumper;

our $Cheat = '';

# Globals from bin/nhc
our ($FastForward);

our ($App, $Game, $Klaymen, $Cursor, $Remainder);
use Games::Neverhood         qw/$App $Game/;
use Games::Neverhood::Sprite qw/$Klaymen $Cursor $Remainder/;
our @EXPORT    = qw/$Game $Klaymen $Cursor/;
our @EXPORT_OK = qw/$Cheat $FastForward $DrawDebug/;

#sprites all_folder fps move_bounds cursor on_set on_unset

our @ReadOnly = qw/all_folder fps cursor setup setdown/;
sub read_only { \@ReadOnly }

sub new {
	my ($class, %arg) = @_;
	my $self = bless \%arg, ref $class || $class;

	my @sprites;
	for(my $i = 0; $i < @{$self->sprites}; $i++) {
		my $sprite = $self->sprites->[$i];
		if(ref $sprite) {
			next if Scalar::Util::blessed($sprite);
			
			$sprite = Games::Neverhood::Sprite->new(
				defined $self->all_folder ? (all_folder => $self->all_folder) : (),
				%$sprite,
			);
		}
		else {
			my $hash = $self->sprites->[++$i];
			my @all = map {
				defined $hash->{$_}
					? ($_, delete $hash->{$_})
					: ()
			} @Games::Neverhood::Sprite::All;
			$sprite = Games::Neverhood::Sprite->new(
				$sprite => $hash,
				defined $self->all_folder ? (all_folder => $self->all_folder) : (),
				@all,
			);
		}
		$sprite->load;
	} continue {
		push @sprites, $sprite;
	}
	$self->sprites(\@sprites);
	$self->{fps} = 24 unless defined $self->fps;
	#bounds
	#cursors
	#setup
	#setdown

	$self;
}

sub cursor_left_right {
	return 'left', 'left' if $_[0] < 320;
	return 'right', 'right';
}
sub cursor_left_forward_right {
	my $range = 100;
	return 'left', 'left' if $_[0] < $range;
	return 'right', 'right' if $_[0] >= 640 - $range;
	return 'forward', 'forward';
}
sub cursor_out {
	my $range = 20;
	return 'left', 'out' if $_[0] < $range;
	return 'right', 'out' if $_[0] >= 640 - $range;
	return;
}

sub delete_clicked {
	$Cursor->clicked(undef);
}

sub klaymen {
	for(@{$_[0]->sprites}) {
		return $Klaymen if $_ == $Klaymen;
	}
}
# sub sprite {
	# $_[1] ~~ $_[0]->sprites;
# }

sub call {
	my (undef, $callback, @arg) = @_;
	$callback->(@arg);
}

###################################ACCESSORS###################################

sub sprites {
	if(@_ > 1) { $_[0]->{sprites} = $_[1]; return $_[0]; }
	$_[0]->{sprites};
}
sub all_folder { $_[0]->{all_folder} }
sub fps { $_[0]->{fps} }
sub move_bounds {
	if(@_ > 1) { $_[0]->{move_bounds} = $_[1]; return $_[0]; }
	$_[0]->{move_bounds};
}
sub cursor {
	my $self = shift;
	$self->{cursor}->(@_) if $self->{cursor};
}
sub on_set {
	my $self = shift;
	$self->{on_set}->(@_) if $self->{on_set};
}
sub on_unset {
	my $self = shift;
	$self->{on_unset}->(@_) if $self->{on_unset};
}

###################################HANDLERS####################################


sub event {
	shift;
	my ($e) = @_;
	if($e->type == SDL_MOUSEBUTTONDOWN and $e->button_button & (SDL_BUTTON_LEFT | SDL_BUTTON_MIDDLE | SDL_BUTTON_RIGHT) and !$Cursor->hide) {
		my @pos = ($e->button_x, $e->button_y);
		my (undef, $event) = $Game->cursors->(@pos);
		$event = 'click' unless defined $event;
		$Cursor->clicked([@pos, $event]);
	}
	elsif($e->type == SDL_MOUSEMOTION) {
		my @pos = ($e->motion_x, $e->motion_y);
		my ($sprite) = $Game->cursors->(@pos);
		$sprite = 'click' unless defined $sprite;
		$Cursor->sprite($sprite);
		$Cursor->pos(\@pos);
	}
	elsif($e->type == SDL_KEYDOWN) {
		my $name = SDL::Events::get_key_name($e->key_sym);
		given($name) {
			when('escape') {

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
						$Game == $Games::Neverhood::Scene::Nursery1 or
						$Game == $Games::Neverhood::Scene::Nursery1OutWindow
					) {
						$Game->set('Nursery::Two');
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

sub move {
	shift;
	my ($step) = @_;
	return unless $step;
	$Remainder += $step;
	$Remainder -= int $Remainder;
	for my $sprite (@{$Game->sprites}, $Cursor) {
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
		for(my $i = 0; $i < @{$sprite->events_sequence}; $i++) {
			my $condition = $sprite->events_sequence->[$i++];
			if(
				ref $condition eq 'CODE' and $Game->call($condition, $sprite)
				or !ref $condition and (
				$condition eq 'true'
				or $sprite->get(undef, $condition) )
			) {
				$Game->call($sprite->events_sequence->[$i], $sprite, $step);
			}
		}
	}

	&move_click;
}

sub move_click {
	return unless my $click = $Cursor->clicked;
	my $event = $click->[2];
	die "click fail\n", Dumper $click unless defined $event;
	for my $sprite (grep ref $_->$event, @{$Game->sprites}) {
		for(my $i = 0; $i < @{$sprite->$event}; $i++) {
			my $condition = $sprite->$event->[$i++];
			if(
				    ref $condition eq 'ARRAY' and $sprite->rect(@$condition)
				or  ref $condition eq 'CODE'  and $Game->call($condition, $sprite)
				or !ref $condition            and $Klaymen->sprite =~ /$condition/
			) {
				my $return = $Game->call($sprite->$event->[$i], $sprite);
				$return = '' unless defined $return;
				unless($return eq 'no') {
					$Game->delete_clicked unless $return eq 'not_yet';
					return;
				}
			}
		}
	}
	if($Game->klaymen and $Klaymen->sprite =~ /^idle/) {
		my $bound;
		if(
			$bound = $Game->bounds and
			$bound->[0] <= $click->[0] and $bound->[1] <= $click->[1]
			and $bound->[2] >= $click->[0] and $bound->[3] >= $click->[1]

			and !$Klaymen->sprite eq 'idle' || ($click->[0] < $Klaymen->pos->[0] - 38 || $click->[0] > $Klaymen->pos->[0] + 38)
		) {
			$Klaymen->move_to(to => $click->[0]);
		}
		$Game->delete_clicked;
		return;
	}

	&move_klaymen;
}

sub move_klaymen {
	return unless $Game->klaymen;
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
					$Klaymen->pos->[0] += 2 * $_[0];
				}
			}
		}
		else {
			#set or do
		}
		# if($Klaymen->pos->[0] == $to) {
			# if($Klaymen->get('idle')) {
				# if(defined $move->{do}) {
					# $M{scene}->call($move->{do}, $move->{sprite}, $click);
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

sub show {
	for(@{$Game->sprites}, $Cursor) {
		$_->show unless $DrawDebug and $_ != $Klaymen and $_ != $Cursor;
	}
}

1;
