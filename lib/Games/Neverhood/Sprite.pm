use 5.01;
use strict;
use warnings;
package Games::Neverhood::Sprite;

use parent 'Games::Neverhood::StorableRW';
use Games::Neverhood::Surface;
use SDL::GFX::Rotozoom;

use File::Spec ();
use Carp ();

# Overloadable Methods:

# use constant
	# vars
		# frame
		# sequence
		# sequences_sequence
		# pos
		# hide
		# mirror
	# name
	# file
	# dir
	# sequences
		# frames
		# offset
		# next_sequence
	# no_cache
	# dont_store

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

# sub this_surface
# sub this_frame
# sub this_frames
# sub this_offset
# sub this_next_sequence

# don't overload this. do your on_new in the game object's on_new
sub new {
	my $class = shift;
	my $self = bless {}, ref $class || $class;
	%$self = %{$self->vars};

	$self->pos([]) unless defined $self->pos;
	$self->pos->[0] //= 0;
	$self->pos->[1] //= 0;
	#hide
	#mirror
	#name
	$self->{surfaces} = {};

	$self;
}

# same here, but game object's on_destroy
# sub DESTROY {}

###############################################################################
# accessors

sub frame {
	my ($self, $frame) = @_;
	if(@_ > 1) {
		if($frame ne 'end' and $frame >= $self->this_frames) {
			# loop back to frame 0, and signify being at the 'end' instead of just frame 0
			$frame = 'end';
		}
		$self->{frame} = $frame;
		# the sprite is moved here. As long as you call this method every frame, everything will be fine
		$self->on_move;
		return $self;
	}
	# we return a dualvar that is both 0 and 'end' when we're signifying that the sprite just looped
	# we're blindly relying on Storable storing this as "end" and not 0
	return Scalar::Util::dualvar(0, 'end') if $self->{frame} eq 'end';
	$self->{frame};
}
sub sequence {
	my ($self, $sequence, $frame) = @_;
	if(@_ > 1) {
		my $ss = $self->sequences->{$sequence} or
			Carp::confess("Sprite: '", $self->name, "' has no sequence: '$sequence'");

		$self->{sequence} = $sequence;
		$self->sequences_sequence($ss);
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
sub sequences_sequence {
	if(@_ > 1) { $_[0]->{sequences_sequence} = $_[1]; return $_[0]; }
	$_[0]->{sequences_sequence};
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
sub name {
	# overload this at will, but know that you can use this default behaviour
	$_[0]->{name};
}

###############################################################################
# constant/subs

use constant {
	file       => undef,
	vars       => {},
	sequences  => undef,
	dir        => 'i',
	no_cache   => undef,
	dont_store => [ 'name', 'surfaces' ],
};

###############################################################################
# handler subs

sub on_move {}

sub on_show {
	my ($self) = @_;
	return if $self->hide;
	
	my $surface = $self->this_surface;
	my $pos     = $self->pos;
	my $offset  = $self->this_offset;
	
	my $x = $pos->[0] + $self->mirror
		? 1 - $surface->w - $offset->[0]
		: $offset->[0]
	;
	my $y = $pos->[1] + $offset->[1];

	$surface->draw_xy($x, $y);
}

sub on_space {}
sub on_click { 'no' }
sub on_out {}
sub on_left {}
sub on_right {}
sub on_up {}
sub on_down {}

###############################################################################
# sequence methods

sub this_surface {
	my ($self) = @_;
	my $surfaces = $self->{surfaces};
	my $surface;
	my $frame;
	if(defined $surfaces->{last_surface_frame} and $surfaces->{last_surface_frame} == ($frame = $self->this_frame)) {
		$surface = $surfaces->{last_surface};
	}
	else {
		if(!$surfaces->{cache} or not $surface = $surfaces->{cache}[$frame]) {
			defined $self->file or Carp::confess("Sprite: '", $self->name, "' must specify a file");
			$surface = Games::Neverhood::Surface->new($self->file, $frame);
			$surfaces->{cache}[$frame] = $surface unless $self->no_cache;
		}
		$surfaces->{last_surface_frame} = $frame;
		$surfaces->{last_surface} = $surface;
	}
	$self->mirror
		# surface_xy( surface, angle, zoom_x, zoom_y, smooth )
		? SDL::GFX::Rotozoom::surface_xy($surface, 0, -1, 1, 0)
		: $surface
	;
}
sub this_frames {
	my ($self) = @_;
	return 0 unless defined(my $ss = $self->sequences_sequence);
	scalar @{$ss->{frames}};
}
sub this_frame {
	my ($self) = @_;
	return unless defined(my $ss = $self->sequences_sequence);
	$ss->{frames}[$self->frame];
}
sub this_offset {
	my ($self) = @_;
	my $ss;
		return [0, 0]
	if !defined($ss = $self->sequences_sequence)
	or !defined(my $offsets = $ss->{offsets});
	
	my $n;
	my $x = $offsets->[$n = $self->frame * 2] // do { warn "Sprite: '", $self->name, "' didn't have an offset '$n'"; 0 };
	my $y = $offsets->[++$n                 ] // do { warn "Sprite: '", $self->name, "' didn't have an offset '$n'"; 0 };
	[$x, $y];
}
sub this_next_sequence {
	my ($self) = @_;
	return unless defined(my $ss = $self->sequences_sequence);
	$ss->{next_sequence};
}

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
	$_->klaymen->moving_to({
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
	my $click = $_->cursor->clicked;
	return
		$click and $rect[2] and $rect[3]
		and $click->[0] >= $rect[0] and $click->[1] >= $rect[1]
		and $click->[0] < $rect[0] + $rect[2] and $click->[1] < $rect[1] + $rect[3]
	;
}

1;
