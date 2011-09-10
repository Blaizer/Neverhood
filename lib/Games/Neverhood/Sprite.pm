use 5.01;
use strict;
use warnings;
package Games::Neverhood::Sprite;

use SDL::Image;
use SDL::Video;
use SDL::Rect;
use SDL::GFX::Rotozoom;
use SDL::Mixer::Channels;
use SDL::Mixer::Samples;

use File::Spec ();
use Carp ();

# Overloadable Methods:

# sub new
	# frame
	# sequence
	# pos
	# hide
	# mirror

# use constant
	# name
	# file
	# dir
	# sequences

# sub on_move
# sub on_show
# sub on_space
# sub on_click
# sub on_out
# sub on_left
# sub on_right
# sub on_up
# sub on_down

# Other Methods:

# sub move_klaymen_to
# sub in_rect

# sub this_sequence
# sub this_sequence_surface
# sub this_sequence_frame
# sub this_sequence_frames
# sub this_sequence_pos
# sub this_sequence_offset

sub new {
	my $class = shift;
	my $self = bless {@_}, ref $class || $class;

	$self->file or Carp::confess("Sprite: '", $self->name // __PACKAGE__, "' must specify a file");

	if($self->sequence) {
		$self->sequence($self->sequence, $self->frame // 0);
	}
	else {
		# gotta still call that on_move from within frame
		$self->frame(0);
	}

	$self->pos([]) unless defined $self->pos;
	$self->pos->[0] //= 0;
	$self->pos->[1] //= 0;
	#hide
	#mirror

	$self->sprite($sprite) if defined $sprite;
	$self;
}

sub DESTROY {}

###############################################################################
# accessors

sub frame {
	my ($self, $frame) = @_;
	if(@_ > 1) {
		if($frame ne 'end' and $frame >= $self->this_sequence_frames) {
			# loop back to frame 0, and signify being at the 'end' instead of just frame 0
			$frame = 'end';
		}
		$self->{frame} = $frame;
		# the sprite is moved here. As long as you call this method every frame, everything will be fine
		$self->on_move;
		return $self;
	}
	# we return a dualvar that is both 0 and 'end' when we're signifying that the sprite just looped
	return Scalar::Util::dualvar(0, 'end') if $self->{frame} eq 'end';
	$self->{frame};
}
sub sequence {
	my ($self, $sequence, $frame) = @_;
	if(@_ > 1) {
		# TODO: might wanna do error checking on $sequence here
		$self->{sequence} = $sequence;
		if(@_ > 2) {
			$self->frame($frame);
		}
		else {
			# we set the frame to 0 for safety, we don't trust you to do it yourself
			# send the current frame in the second arg if you wanna retain it
			$self->frame(0);
		}
		return $self;
	}
	$self->{sequence};
}
sub pos {
	if(@_ > 1) { $_[0]->{pos} = $_[1]; return $_[0]; }
	$_[0]->{pos};
}
sub hide {
	if(@_ > 1) { $_[0]->{hide} = $_[1]; return $_[0]; }
	$_[0]->{hide};
}
sub mirror {
	if(@_ > 1) { $_[0]->{mirror} = $_[1]; return $_[0]; }
	$_[0]->{mirror};
}

###############################################################################
# constant/subs

use constant {
	name      => undef, # TODO: might wanna make this a sub with error checking and a state var
	file      => undef,
	sequences => undef, # TODO: might wanna put error checking here
	dir       => 'i',
}

###############################################################################
# handler subs

sub on_move {}

sub on_show {
	# TODO: rewrite this
	my ($self) = @_;
	return if $self->hide;
	my $surface = $self->this_surface;
	die 'no surface', $self->flip ? '_flip' : '', ' for: ', File::Spec->catfile(@{$self->folder}, $self->name) unless ref $surface;
	my $h = $surface->h / $self->frames;
	SDL::Video::blit_surface(
		$surface,
		SDL::Rect->new(0, $h * $self->this_sequence_frame, $surface->w, $h),
		$Games::Neverhood::App,
		SDL::Rect->new(
			$self->pos->[0] + (
				$self->flip
				? -$surface->w - $self->offset->[0] + 1
				: $self->offset->[0]
			),
			(
				$self->on_ground
				? 480 - $self->pos->[1] + $self->offset->[1] - $h
				: $self->pos->[1] + $self->offset->[1]
			), 0, 0
		)
	);
}

sub on_space {}
sub on_click { 'no' }
sub on_out {}
sub on_left {}
sub on_right {}
sub on_up {}
sub on_down {}

###############################################################################
# other

sub move_klaymen_to {
	# TODO: this needs to be finalised
	my ($sprite, %arg) = @_;
	for(grep defined, @arg{qw/left right/}) {
		if(ref) {
			$_->[0] = [@$_] if !ref $_->[0];
		}
		else {
			$_ = [[$_]];
		}
	}
	$Klaymen->moving_to({
		%arg,
		sprite => $sprite,
	});
	# sprite => $sprite,
	# left => 1 || [1, 2, 3] || [[1, 2, 3], 4],
	# right => 1 || [1, 2, 3] || [[1, 2, 3], 4],
	# do => sub { $_[0]->hide = 1 },
	# set => ['idle', 0, 2, 1],
	$sprite;
}

sub in_rect {
	my ($sprite, @rect) = @_;
	my $click = Games::Neverhood->cursor->clicked;
	return
		$click and $rect[2] and $rect[3]
		and $click->[0] >= $rect[0] and $click->[1] >= $rect[1]
		and $click->[0] < $rect[0] + $rect[2] and $click->[1] < $rect[1] + $rect[3]
	;
}

sub this_sequence {

}
sub this_sequence_surface {

}
sub this_sequence_frame {

}
sub this_sequence_frames {

}
sub this_sequence_pos {

}
sub this_sequence_offset {

}

1;
