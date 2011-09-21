use 5.01;
use strict;
use warnings;
package Games::Neverhood::Scene;

use SDL;
use SDL::Video;
use SDL::Events;

use Carp ();

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
use Games::Neverhood qw/$Remainder $Debug/;
use Games::Neverhood::Sprite;
use Games::Neverhood::OrderedHash;

# Overloadable Methods:

# sub on_new
# sub on_destroy

# use constant
	# vars
		# sprites
		# frame
	# sprites_list
	# all_dir
	# fps
	# cursor_type
	# klaymen_move_bounds
	# music

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

# don't overload this, use on_new and vars
sub new {
	my ($self, $unset_name) = @_;
	$self = $self->SUPER::new;
	%$self = %{$self->vars};

	my $sprites = Games::Neverhood::OrderedHash->new;
	my $name;
	for my $sprite (@{$self->sprites_list}) {
		if(ref $sprite) {
			$name = $sprite->name or Carp::confess("All sprites must have a (unique) name");
		}
		else {
			no strict 'refs';
			$name = $sprite;
			my $sprite_class = ref($self) .'::'. $name;
			$sprite = $sprite_class->new;
			$sprite->{name} = $name;
		}
	} continue {
		$sprites->{$name} = $sprite;
	}
	$self->{sprites} = $sprites;

	$self->frame(0);
	$self->on_new($unset_name);

	for my $sprite (@{$self->sprites}) {
		if(defined $sprite->sequence) {
			$sprite->sequence($sprite->sequence);
		}
		else {
			# gotta still call that on_move from within frame
			$sprite->frame(0);
		}
	}
	$self;
}
sub on_new {}

# don't overload this either, use on_destroy
# sub DESTROY {}
sub on_destroy {}

###############################################################################
# accessors

sub sprites { $_[0]->{sprites} }
sub frame {
	if(@_ > 1) {
		$_[0]->{frame} = $_[1];
		$_[0]->on_move;
		return $_[0];
	}
	$_[0]->{frame};
}

###############################################################################
# constant/subs

use constant {
	vars                => {},
	sprites_list        => [],
	fps                 => 24,
	cursor_type         => 'click',
	move_klaymen_bounds => undef,
	music               => undef,
};

###############################################################################
# handler subs

sub on_move  {}
sub on_show  {}
sub on_space {}
sub on_click { 'no' }
sub on_out   {}
sub on_left  {}
sub on_right {}
sub on_up    {}
sub on_down  {}

sub event {
	my ($self, $e) = @_;
	if($e->type == SDL_MOUSEMOTION) {
		$self->cursor->pos([$e->motion_x, $e->motion_y]);
	}
	elsif($e->type == SDL_MOUSEBUTTONDOWN and $e->button_button & (SDL_BUTTON_LEFT | SDL_BUTTON_MIDDLE | SDL_BUTTON_RIGHT)) {
		my $pos = [$e->button_x, $e->button_y];
		$self->cursor->pos($pos);
		if($self->cursor->sequence eq 'click') {
			$self->cursor->clicked($pos);
		}
		else {
			my $method = "on_" . $self->cursor->sequence;
			$self->$method;
			$self->cursor->clicked(undef);
		}
	}
	elsif($e->type == SDL_KEYDOWN) {
		return if $e->key_mod & (KMOD_ALT | KMOD_CTRL | KMOD_SHIFT | KMOD_META);
		my $name = SDL::Events::get_key_name($e->key_sym);
		given($name) {
			when('escape') {
				# $self->set('Menu');
			}
			when('space') {
				$self->on_space;
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
			$self->cursor->hide(!$e->active_gain);
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

	my $return = $self->on_click // '';
	if($return eq 'no_but_keep') {
		return;
	}
	elsif($return ne 'no') {
		$self->cursor->clicked(undef);
		return;
	}

	for my $sprite (@{$self->sprites}) {
		my $return = $self->on_click // '';
		if($return eq 'no_but_keep') {
			return;
		}
		elsif($return ne 'no') {
			$self->cursor->clicked(undef);
			return;
		}
	}
	if($self->sprites->{klaymen} and !$self->klaymen->no_interrupt) {
		my $bound;
		if(
			$bound = $self->move_klaymen_bounds and
			$bound->[0] <= $click->[0] and $bound->[1] <= $click->[1] and
			$bound->[2] >= $click->[0] and $bound->[3] >= $click->[1] and

			!$self->klaymen->sprite eq 'idle' ||
			($click->[0] < $self->klaymen->pos->[0] - 38 || $click->[0] > $self->klaymen->pos->[0] + 38)
		) {
			$self->klaymen->move_to(to => $click->[0]);
		}
		$self->cursor->clicked(undef);
		return;
	}
}

sub _move_sprites {
	my ($self, $step) = @_;
	$Remainder += $step;
	if($Remainder >= 1) {
		$Remainder--;

		# on_move is called inside the frame method
		$self->frame($self->frame + 1) if $self->frames;

		for my $sprite (@{$self->sprites}, $self->cursor) {
			# on_move is called inside the frame method
			$sprite->frame($sprite->frame + 1);
		}
	}
}

sub show {
	my ($self, $time) = @_;

	$self->on_show($time);

	for my $sprite (reverse @{$self->sprites}, $self->cursor) {
		$sprite->on_show;
	}
}

1;
