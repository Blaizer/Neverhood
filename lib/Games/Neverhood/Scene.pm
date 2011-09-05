use 5.01;
use strict;
use warnings;
package Games::Neverhood::Scene;

use SDL;
use SDL::Video;
use SDL::Events;

use parent
	'Games::Neverhood',
	'Exporter',
;

# The user entered text for the "cheat" system
our $Cheat = '';

# Globals from bin/nhc
our ($FastForward);

our @EXPORT_OK = qw/$Cheat $FastForward/;

our ($Remainder, $Debug);
use Games::Neverhood         qw/$Remainder $Debug/;
use Games::Neverhood::Sprite;

use Games::Neverhood::OrderedHash;

# sub new
	# sprites
	# video
	# frame

# sub DESTROY

# constant|sub sprites_list
# constant|sub all_dir
# constant|sub fps
# constant|sub cursor_sequence
# constant|sub move_klaymen_bounds
# constant|sub music
# constant|sub name

# sub event
# sub move
# sub show

# sub on_move
# sub on_show
# sub on_space
# sub on_click
# sub on_out
# sub on_left
# sub on_right
# sub on_up
# sub on_down

sub new {
	my ($class, %arg) = @_;
	my $class = ref $class || $class;
	my $self = bless \%arg, $class;

	my $sprites = Games::Neverhood::OrderedHash->new;
	for my $name (@{$self->sprites_list}) {
		my $sprite;
		if(ref $name) {
			$sprite = $name;
			$name = $sprite->name;
		}
		else {
			no strict 'refs';
			my $sprite_class = "$class::$name";
			push @{"$sprite_class::ISA"}, 'Games::Neverhood::Sprite';
			$sprite = $sprite_class->new;

			# yucky all_dir setting from scene to sprite for the time being
			*{"$sprite_class::all_dir"} = \&{"$class::all_dir"} unless eval { $sprite->dir };
		}
	} continue {
		$sprites->{$name} = $sprite;
	}
	$self->{sprites} = $sprites;

	# video

	$self->frame(0);

	$self;
}

sub DESTROY {

}

###############################################################################
# accessors

sub sprites { $_[0]->{sprites} }
sub video   { $_[0]->{video}   }
sub frame {
	if(@_ > 1) { $_[0]->{frame} = $_[1]; return $_[0]; }
	$_[0]->{frame};
}

###############################################################################
# constant/subs

use constant {
	sprites_list        => [],
	all_dir             => 'i',
	fps                 => 24,
	cursor_sequence     => 'click',
	move_klaymen_bounds => undef,
	music               => undef,
	name                => undef,
}

###############################################################################
# handler subs

sub on_move  {}
sub on_show  {}
sub on_space {}
sub on_click {}
sub on_out   {}
sub on_left  {}
sub on_right {}
sub on_up    {}
sub on_down  {}

sub event {
	my ($self, $e) = @_;
	if($e->type == SDL_MOUSEMOTION) {
		$self->cursor->pos([$e->motion_x, $e->motion_y]);
		$self->cursor->sequence($self->cursor_sequence);
	}
	elsif(
		$e->type == SDL_MOUSEBUTTONDOWN and $e->button_button & (SDL_BUTTON_LEFT | SDL_BUTTON_MIDDLE | SDL_BUTTON_RIGHT)
		and !$self->cursor->hide
	) {
		my @pos = ($e->button_x, $e->button_y);
		$self->cursor->pos(\@pos);
		$self->cursor->clicked(\@pos);
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
				$Cheat = '!' if length $Cheat > length 'happybirthdayklaymen';
			}
			when('return') {
				if($Cheat eq 'fastforward') {
					$FastForward = !$FastForward;
					$self->dt(1 / ($self->fps * 3));
				}
				elsif($Cheat eq 'screensnapshot') {
					my $file = File::Spec->catfile('', 'NevShot.bmp');
					SDL::Video::save_BMP($self, $file) and warn "Error saving screenshot to $file: ", SDL::get_error;
				}
				elsif($Cheat eq 'happybirthdayklaymen' and $self eq 'Scene::Nursery::One') {
					$self->set('Scene::Nursery::Two');
				}
				elsif($Cheat eq 'letmeoutofhere' and $self eq 'Scene::Nursery::Two') {
					$self->set('Scene::Outsidesomewhere...');
				}
				elsif($Cheat eq 'please') {
					$self->GG->{something} = 'something else';
					$self->set('Scene::Shack');
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

sub move {
	my ($self, $step) = @_;
	return unless $step;

	&_move_click;
	&_move_sprites;
	# &_move_klaymen;
}

sub _move_click {
	my ($self, $step) = @_;
	my $click = $self->cursor->clicked;
	if($click) {
		my $return = $self->on_click // '';
		if($return eq 'yes') {
			$self->cursor->clicked(undef);
			return;
		}
		elsif($return eq 'yes_but_keep') {
			return;
		}

		if($self->cursor->sequence eq 'click') {
			for my $sprite (@{$self->sprites}) {
				my $return = $object->on_click($self) // '';
				if($return eq 'yes') {
					$self->cursor->clicked(undef);
					return;
				}
				elsif($return eq 'yes_but_keep') {
					return;
				}
			}
			if($self->sprites->{klaymen} and !$self->klaymen->no_interrupt) {
				my $bound;
				if(
					$bound = $self->move_klaymen_bounds and
					$bound->[0] <= $click->[0] and $bound->[1] <= $click->[1] and
					$bound->[2] >= $click->[0] and $bound->[3] >= $click->[1] and

					!$self->klaymen->sprite eq 'idle' || ($click->[0] < $Klaymen->pos->[0] - 38 || $click->[0] > $Klaymen->pos->[0] + 38)
				) {
					$self->klaymen->move_to(to => $click->[0]);
				}
				$Cursor->clicked(undef);
				return;
			}
		}
		elsif($self->cursor->sequence eq 'something else...') {
		}
	}
}

sub _move_sprites {
	my ($self, $step) = @_;
	$Remainder += $step;
	if($Remainder >= 1) {
		$Remainder--;

		$self->frame($self->frame + 1);
		$self->on_move;

		for my $sprite (@{$self->sprites}, $Cursor) {
			next unless $sprite;
			my $frame = $sprite->frame + 1;
			if($frame >= @{$sprite->this_sequence}) {
				$frame = 'end';
			}
			$sprite->frame($frame);
			$sprite->on_move($self);
		}
	}
}

# sub _move_klaymen {
	# my ($self, $step, $app) = @_;
	# return unless $self->klaymen;
	# if($Klaymen->sprite eq 'idle') {
		# if(defined $Klaymen->blink_in) {
			# $Klaymen->blink_in($Klaymen->blink_in - $_[0]);
			# $Klaymen->random_in($Klaymen->random_in - $_[0]);
			# if($Klaymen->blink_in <= 0) {
				# $Klaymen->sequence(1);
				# $Klaymen->blink_in(undef);
			# }
			# if($Klaymen->random_in <= 0) {
				# $Klaymen->sprite('idle_random_' . int rand 5);
				# $Klaymen->random_in(undef);
			# }
		# }
		# $Klaymen->blink_in(int rand(40) + 30) unless defined $Klaymen->blink_in;
		# $Klaymen->random_in(int rand(40) + 600) unless defined $Klaymen->random_in;
	# }
	# else {
		# $Klaymen->blink_in(undef);
		# $Klaymen->random_in(undef);
	# }
	# if(my $move = $Klaymen->moving_to) {
		# my ($to, @type);
		# {
			# no warnings 'uninitialized';
			# my $min = 1e100;
			# for(qw/left right to/) {
				# my $v;
				# if($_ eq 'to') {
					# $v = $move->{to};
				# }
				# else {
					# (undef, $v) = each @{$move->{$_}[0]};
				# }
				# next unless defined $v;
				# my $new = abs($v - $Klaymen->pos->[0]);
				# if($new < $min) {
					# ($min, $to) = ($new, $v);
					# @type = $_;
				# }
				# elsif($new == $min and $to == $v) {
					# push @type, $_;
				# }
				# redo unless $_ eq 'to';
			# }
		# }
		# ;#( $maximum, $minimum )
		# my $adjust = (5,  );
		# my @shuffle = (20, $adjust);
		# my @slide = (100, $shuffle[0]);
		# my @walk_stop = (40, $shuffle[0]);
		# my $further = abs($to - $Klaymen->pos->[0]);
		# my $dir = $to <=> $Klaymen->pos->[0];
		# my $left = $dir - 1;

		# if($further) {
			# if($Klaymen->sprite eq 'idle') {
				# if($further <= $adjust) {
					# $Klaymen->pos->[0] += 2 * $_[0];
				# }
			# }
		# }
		# else {
			# set or do
		# }
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
	# }
# }

sub show {
	my ($self, $time) = @_;
	for(reverse @{$self->sprites}, $Cursor) {
		$_->show;
	}
}

1;
