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

# Overloadable Methods and what they should return:

# sub on_new
# sub on_destroy

# use constant
	# vars            {}
		# sprites    Games::Neverhood::OrderedHash->new
		# frame      0
	# sprites_list    []
	# fps             0
	# cursor_type     ""
	# music           0
	# rect

# event
	# sub on_space
	# sub on_out
	# sub on_left
	# sub on_right
	# sub on_up
	# sub on_down
# move
	# sub on_click
	# sub on_move
# show
	# sub on_show

# don't overload this, use on_new, sprites_list and vars
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
			$name = $sprite;
			my $sprite_class = ref($self) .'::'. $name;
			my $sprite_isa = $sprite_class . '::ISA';
			{
				no strict 'refs';
				@$sprite_isa = 'Games::Neverhood::Sprite' unless @$sprite_isa;
			}
			$sprite = $sprite_class->new;
			$sprite->{name} = $name;
		}
	} continue {
		$sprites->{$name} = $sprite;
	}
	$self->{sprites} = $sprites;

	$self->{frame} = 0;
	$self->on_new($unset_name);

	for my $sprite (@{$self->sprites}) {
		if(defined $sprite->sequence) {
			$sprite->sequence($sprite->sequence);
		}
		else {
			# gotta still call that on_move from within frame
			$sprite->frame($sprite->frame // 0);
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
	music               => undef,
	rect                => undef,
};

###############################################################################
# handler subs

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
		elsif($self->cursor_type eq 'out') {
			$self->cursor->clicked(undef);
			$self->on_out;
		}
		else {
			my $method = "on_" . $self->cursor->sequence;
			$self->$method;
		}
	}
	elsif($e->type == SDL_KEYDOWN) {
		return if $e->key_mod & (KMOD_ALT | KMOD_CTRL | KMOD_SHIFT | KMOD_META);
		my $name = SDL::Events::get_key_name($e->key_sym);
		given($name) {
			when('escape') {
				$self->set('Menu');
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
					$self->app->dt(1 / ($self->fps * 3));
				}
				elsif($Cheat eq 'screensnapshot') {
					my $file = File::Spec->catfile('', 'NevShot.bmp'); # TODO: this is wrong on stuff other than windows...
					SDL::Video::save_BMP($self->app, $file) and warn "Error saving screenshot to $file: ", SDL::get_error;
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
sub on_space   {}
sub on_out     {}
sub on_left    {}
sub on_right   {}
sub on_forward {}
sub on_up      {}
sub on_down    {}

sub move {
	my ($self, $step) = @_;
	return unless $step;
	$Remainder += $step;
	if($Remainder >= 1) {
		$Remainder--;

		$self->on_click if $self->cursor->clicked;

		# on_move is called within the frame method
		$self->frame($self->frame + 1);
		$self->cursor->frame($self->cursor->frame + 1);
	}
}
sub on_click {
	my ($self) = @_;
	$self->cursor->clicked(undef);
}
sub on_move {
	my ($self) = @_;
	for my $sprite (@{$self->sprites}) {
		# on_move is called within the frame method
		$sprite->frame($sprite->frame + 1);
	}
}

sub show {
	my ($self, $time) = @_;
	$self->on_show($time);
	$self->cursor->show;
}
sub on_show {
	my ($self) = @_;
	for my $sprite (reverse @{$self->sprites}) {
		$sprite->show;
	}
}

###############################################################################
# other

BEGIN { *in_rect = \&Games::Neverhood::Sprite::in_rect }

1;
