package Games::Neverhood::Scene;
use 5.01;
use strict;
use warnings;

use SDL::Events;

use parent
	'Games::Neverhood::GameMode',
	'Exporter',
;

use Data::Dumper;

# The user entered text for the "cheat" system
our $Cheat = '';

# Globals from bin/nhc
our ($FastForward);

our @EXPORT_OK = qw/$Cheat $FastForward/;

our ($Debug, $Klaymen, $Cursor, $Remainder);
use Games::Neverhood         qw/$Debug/;
use Games::Neverhood::Sprite qw/$Klaymen $Cursor $Remainder/;

use Games::Neverhood::OrderedHash;

# sprites        OrderedHash of sprites in scene
# all_archive    archive to be applied as a default to sprites
# fps
# cursor_out     boolean for click or out cursor
# music
# on_set
# on_unset       run before on_set, when a scene is set
# on_out
# on_space

use constant store => qw/sprites/;

sub new {
	my ($class, %arg) = @_;
	my $self = bless \%arg, ref $class || $class;

	# all_dir
	my $sprites = Games::Neverhood::OrderedHash->new;
	for(my $i = 0; $i < @{$self->sprites}; $i++) {
		my $sprite = $self->sprites->[$i];
		if(ref $sprite) {
			unless(eval { $sprite->isa('Games::Neverhood::Sprite') }) {
				$sprite = Games::Neverhood::Sprite->new(
					defined $self->all_dir ? (all_dir => $self->all_dir) : (),
					%$sprite,
				);
			}
		}
		else {
			my $hash = $self->sprites->[++$i];
			$sprite = Games::Neverhood::Sprite->new(
				$sprite => $hash,
				defined $self->all_dir ? (all_dir => $self->all_dir) : (),
				map {
					defined $hash->{$_}
						? ($_, delete $hash->{$_})
						: ()
				} Games::Neverhood::Sprite->all,
			);
		}
	} continue {
		$sprites->{$sprite->name} = $sprite;
	}
	$self->{sprites} = $sprites;
	$self->{fps}    //= 24;
	$self->{cursor} //= 'click';
	# music
	# on_set
	# on_unset
	# on_out
	# on_space

	$self;
}

###############################################################################
### Accessors

sub sprites { $_[0]->{sprites} }
sub all_dir { $_[0]->{all_dir} }
sub fps     { $_[0]->{fps} }
sub cursor  { $_[0]->{cursor} }
sub music   { $_[0]->{music} }
sub on_set   { $_[0]->{on_set}->  ($_[0]) if $_[0]->{on_set} }
sub on_unset { $_[0]->{on_unset}->($_[0]) if $_[0]->{on_unset} }
sub on_out   { $_[0]->{on_out}->  ($_[0]) if $_[0]->{on_out} }
sub on_space { $_[0]->{on_space}->($_[0]) if $_[0]->{on_space} }

###############################################################################
### Handlers

sub event {
	my ($self, $e) = @_;
	if($e->type == SDL_MOUSEMOTION) {
		$Cursor->pos([$e->motion_x, $e->motion_y]);
		$Cursor->sprite($self->cursor_sprite);
	}
	elsif(
		$e->type == SDL_MOUSEBUTTONDOWN and $e->button_button & (SDL_BUTTON_LEFT | SDL_BUTTON_MIDDLE | SDL_BUTTON_RIGHT)
		and !$Cursor->hide
	) {
		my @pos = ($e->button_x, $e->button_y);
		$Cursor->pos(\@pos);
		$Cursor->clicked([@pos, $self->cursor_sprite eq 'click' ? 'click' : 'out');
	}
	elsif($e->type == SDL_KEYDOWN) {
		return if $e->key_mod & (KMOD_ALT | KMOD_CTRL | KMOD_SHIFT | KMOD_META);
		my $name = SDL::Events::get_key_name($e->key_sym);
		given($name) {
			when('escape') {
				# $self->set('Menu');
			}
			when(/^[a-z]$/) {
				$Cheat .= $name;
				$Cheat = '-' if length $Cheat > length 'happybirthdayklaymen';
			}
			when('return') {
				if($Cheat eq 'fastforward') {
					$FastForward = !$FastForward;
					# $App->dt( );
				}
				elsif($Cheat eq 'happybirthdayklaymen' and $self eq 'Scene::Nursery::One') {
					$self->set('Scene::Nursery::Two');
				}
				$Cheat = '';
			}
		}
	}
	elsif($e->type == SDL_ACTIVEEVENT) {
		if($e->active_state & SDL_APPMOUSEFOCUS) {
			$Cursor->hide(!$e->active_gain);
		}
	}
}

sub cursor_sprite {
	my ($self) = @_;
	if($self->cursor eq 'click') {
		'click';
	}
	elsif($self->cursor eq 'out') {
		$pos[0] <        10 ? 'left'  :
		$pos[0] >= 640 - 10 ? 'right' :
		'click';
	}
	else {
		die 'DEBUG: Unknown cursor: ', $self->cursor;
		'';
	}
}

sub move {
	my (undef, $step) = @_;
	return unless $step;
	&move_click;
	&move_sprites;
	&move_klaymen;
}

sub move_click {
	my ($self) = @_;
	my ($
	if($cursor_sprite eq 'click') {
		for my $sprite (reverse @{$self->sprites}) {
			my $return = $sprite->on_click // '';
			unless($return eq 'no') {
				$Cursor->clicked(undef) unless $return eq 'not_yet';
				return;
			}
		}
		if($self->sprites->{klaymen} and !$Klaymen->no_interrupt) {
			my $bound;
			if(
				$bound = $self->bounds and
				$bound->[0] <= $click->[0] and $bound->[1] <= $click->[1] and
				$bound->[2] >= $click->[0] and $bound->[3] >= $click->[1] and

				!$Klaymen->sprite eq 'idle' || ($click->[0] < $Klaymen->pos->[0] - 38 || $click->[0] > $Klaymen->pos->[0] + 38)
			) {
				$Klaymen->move_to(to => $click->[0]);
			}
			$Cursor->clicked(undef);
			return;
		}
	}
	elsif($cursor_sprite eq 'left' or $cursor_sprite eq 'right') {
		$self->on_out;
	}
}

sub move_sprites {
	my ($self, $step) = @_;
	$Remainder += $step;
	if($Remainder >= 1) {
		$Remainder--;
		for my $sprite (@{$self->sprites}, $Cursor) {
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
					ref $condition eq 'CODE' and $self->call($condition, $sprite)
					or !ref $condition and (
					$condition eq 'true'
					or $sprite->get(undef, $condition) )
				) {
					$self->call($sprite->events_sequence->[$i], $sprite, $step);
				}
			}
		}
	}
}

sub move_klaymen {
	my ($self, $step, $app) = @_;
	return unless $self->klaymen;
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
	my ($self, $time) = @_;
	for(@{$self->sprites}, $Cursor) {
		$_->show;
	}
}

1;
