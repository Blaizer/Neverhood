use 5.01;
use strict;
use warnings;
package Games::Neverhood::Sprite;

use parent 'Games::Neverhood::StorableRW';
use Games::Neverhood qw/$ShareDir/;

use SDL;
use SDL::Image;
use SDL::Video;
use SDL::Rect;
use SDL::PixelFormat;
use SDL::Color;
use SDL::Palette;
use SDL::GFX::Rotozoom;

use File::Spec ();
use Carp ();

# Overloadable Methods:

# use constant
	# vars
		# frame
		# sequence
		# pos
		# hide
		# mirror
	# name
	# file
	# dir
	# rect
	# alpha
	# dont_store
	# sequences
		# frames
		# offsets
		# clips
		# next_sequence

# sub on_move
# sub on_show

# sub this_frame
# sub this_frames
# sub this_offset
# sub this_next_sequence

# don't overload this. do your on_new in the game object's on_new
sub new {
	my $class = shift;
	my $self = bless {}, ref $class || $class;
	%$self = %{$self->vars};

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
			$frame = defined $self->sequence ? 'end' : 0;
		}
		$self->{frame} = $frame;
		# the sprite is moved here. As long as you call this method every frame, everything will be fine
		$self->on_move;
		return $self;
	}
	# we return a dualvar that is both 0 and 'end' when we're signifying that the sprite just looped
	# we're blindly relying on Storable storing this as "end" and not 0
	$self->{frame} //= 0;
	return Scalar::Util::dualvar(0, 'end') if $self->{frame} eq 'end';
	$self->{frame};
}
sub sequence {
	my ($self, $sequence, $frame) = @_;
	if(@_ > 1) {
		$self->sequences->{$sequence} or Carp::confess("Sprite '", $self->name, "' has no sequence: '$sequence'");
		$self->{sequence} = $sequence;
		if(@_ > 2) {
			$self->frame($frame // 0);
		}
		else {
			# we set the frame to 0 for safety, we don't trust you to do it yourself
			# send the current frame in the second arg if you wanna retain it
			$self->frame(0);
		}
		return $self;
	}
	wantarray ? ($self->{sequence}, $self->frame) : $self->{sequence};
}
sub pos {
	if(@_ > 1) { $_[0]->{pos} = $_[1]; return $_[0]; }
	$_[0]->{pos} ||= [0, 0];
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
	rect       => undef,
	alpha      => undef,
	palette    => undef,
	dont_store => [ 'name', 'this_surface' ],
};

###############################################################################
# handler subs

sub on_move {}

sub show {
	# don't overload this, overload pos, this_offset, this_clip, etc.
	my ($self) = @_;
	return if $self->hide;

	my $surface = $self->this_surface;
	my $pos     = $self->pos;
	my $offset  = $self->this_offset;
	my $clip    = $self->this_clip;

	my $x = $pos->[0] + ($self->mirror
		? 1 - $surface->w - $offset->[0]
		: $offset->[0]
	);
	my $y = $pos->[1] + $offset->[1];

	$self->_show_surface_at($surface, [$x, $y], $clip);
	$self->on_show;
}
sub on_show {
	# overload this if you wanna do something after showing the sprite
}
sub _show_surface_at {
	# don't overload this
	my (undef, $surface, $pos, $clip) = @_;
	SDL::Video::blit_surface(
		$surface,
		SDL::Rect->new($clip ? @$clip : (0, 0, $surface->w, $surface->h)),
		$;->app,
		SDL::Rect->new(@$pos, 0, 0)
	);
}
sub show_at {
	# don't overload this
	my ($self, $pos, $clip) = @_;
	$self->_show_surface_at($self->this_surface, $pos, $clip);
}

###############################################################################
# sequence methods

sub this_surface {
	# don't overload this
	my ($self) = @_;
	my ($dir, $file, $frame, $mirror, $palette, $alpha) = ($self->dir, $self->file, $self->this_frame, $self->mirror, $self->palette, $self->alpha);

	defined $file or Carp::confess("Sprite '", $self->name, "' must specify a file");
	defined $dir  or Carp::confess("Sprite '", $self->name, "' must specify a dir");

	if(my $this_surface = $self->{this_surface}) {
		if(
			$this_surface->{dir} eq $dir
			and $this_surface->{file} == $file
			and !exists $this_surface->{frame} || $this_surface->{frame} == $frame
			and !($this_surface->{mirror} xor $mirror)
			and !defined $this_surface->{palette} && !defined $palette || $this_surface->{palette} == $palette
			and !defined $this_surface->{alpha}   && !defined $alpha   || $this_surface->{alpha}   == $alpha
		) {
			return $self->{this_surface}{surface};
		}
	}

	my ($filename, $is_sequence);
	if(-d File::Spec->catdir($ShareDir, $dir, $file)) {
		$is_sequence = 1;
		$filename = File::Spec->catfile($ShareDir, $dir, $file, $frame);
	}
	else {
		$filename = File::Spec->catfile($ShareDir, $dir, $file);
	}
	$filename .= '.tga';

	my $surface = SDL::Image::load($filename)
		or Carp::confess("Sprite '", $self->name, "could not load image '$filename': ", SDL::get_error);

	if($mirror) {
		$surface = SDL::GFX::Rotozoom::surface_xy($surface, 0, -1, 1, 0);
	}

	if(defined $palette) {
		my @colors;
		if(eval { $palette->isa('Games::Neverhood::Sprite') }) {
			@colors = $palette->this_surface->format->palette->colors;
		}
		else {
			$filename = File::Spec->catfile($ShareDir, 'i', $palette . '.03');
			open PALETTE, $filename or Carp::confess("Could not open palette '$filename': $!");
			binmode PALETTE;
			my $buf;
			@colors = map SDL::Color->new(unpack 'CCC', do{ read PALETTE, $buf, 4; $buf }), 0..255;
		}
		SDL::Video::set_palette($surface, SDL_LOGPAL, 0, @colors) or Carp::confess("Setting palette '$palette' failed");
	}

	if(defined $alpha) {
		SDL::Video::set_color_key(
			$surface,
			SDL_SRCCOLORKEY | SDL_RLEACCEL,
			$surface->format->palette->color_index($alpha)
		);
	}

	$self->{this_surface} = {
		surface => $surface,
		dir     => $dir,
		file    => $file,
		mirror  => $mirror,
		palette => $palette,
		alpha   => $alpha,
		$is_sequence ? (frame => $frame) : (),
	};

	$surface;
}

sub this_frames {
	my ($self) = @_;
	return 0 unless defined $self->sequence;
	scalar @{$self->this_sequences->{frames}};
}
sub this_frame {
	my ($self) = @_;
	return 0 unless defined $self->sequence;
	$self->this_sequences->{frames}[$self->frame];
}
sub this_offset {
	my ($self) = @_;
	my $ss;
	my $offsets;
		return [0, 0]
	if !defined $self->sequence
	or not $offsets = $self->this_sequences->{offsets}
	or @$offsets <= (my $n = $self->this_frame * 2) + 1;

	[ @$offsets[$n, $n+1] ];
}
sub this_clip {
	my ($self) = @_;
	my $ss;
	my $clips;
		return
	if !defined $self->sequence
	or not $clips = $self->this_sequences->{clips}
	or @$clips <= (my $n = $self->this_frame * 4) + 3;

	[ @$clips[$n..$n+3] ];
}
sub this_next_sequence {
	my ($self) = @_;
	return unless defined $self->sequence;
	$self->this_sequences->{next_sequence};
}
sub this_sequences {
	# you shouldn't overload this, it's just a convenience method
	my ($self) = @_;
	$self->sequences->{$self->sequence};
}

###############################################################################
# other

sub in_rect {
	my ($self) = @_;
	my $rect = $self->rect;
	my $click = $;->cursor->clicked;
	return
		$click and $rect->[2] and $rect->[3]
		and $click->[0] >= $rect->[0] and $click->[1] >= $rect->[1]
		and $click->[0] < $rect->[0] + $rect->[2] and $click->[1] < $rect->[1] + $rect->[3]
	;
}

1;
