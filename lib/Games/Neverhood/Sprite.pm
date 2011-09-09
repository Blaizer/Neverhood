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
	# name
	# frame
	# sequence
	# pos
	# hide
	# mirror

# use constant
	# file
	# sequences
	# dir
	# frames

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
# sub click_in_rect

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
	
	#name
	# frame will get set to the default of 0 when we set the sequence
	my $frame = $self->frame;
	$self->sequence($self->sequence) if $self->sequence;
	$self->frame($frame) if $frame;
	
	$self->pos([])     unless defined $self->pos;
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

sub name {
	$_[0]->{name};
}
sub frame {
	my ($self, $frame) = @_;
	if(@_ > 1) {
		if($frame >= $self->this_sequence_frames) {
			# loop back to frame 0
			$_[0]->{frame} = 0;
		}
		else {
			$_[0]->{frame} = $frame;
		}
		# the sprite is moved here. As long as you call this method every frame, everything will be fine
		$_[0]->on_move;
		return $_[0];
	}
	$_[0]->{frame};
}
sub sequence {
	if(@_ > 1) {
		$_[0]->{sequence} = $_[1];
		# we set the frame to 0 for safety, we don't trust you to do it yourself
		# save the value in frame and set it after this if you wanna retain it
		$_[0]->frame(0);
		return $_[0];
	}
	$_[0]->{sequence};
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
	file      => undef,
	sequences => undef,
	dir       => 'i',
	frames    => 0,
}

###############################################################################
# handler subs

sub on_move {}

sub on_show {
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
sub on_click {}
sub on_out {}
sub on_left {}
sub on_right {}
sub on_up {}
sub on_down {}

###############################################################################

sub sprites { $_[0]->{sprites} }
sub sprite {
	if(@_ > 1) {
		$_[0]->sprites and defined $_[0]->sprites->{$_[1]};
		$_[0]->{sprite} = $_[1];
		$_[0]->{this_sprite} = $_[0]->sprites->{$_[1]};
		return $_[0];
	}
	$_[0]->{sprite};
}
sub frame :lvalue {
	if(@_ > 1) {
		$_[0]->{frame} = $_[1] + $Remainder;
		$_[0]->to_frame($_[1], '');
		return $_[0];
	}
	$_[0]->{frame};
}
sub sequence {
	if(@_ > 1) { $_[0]->{sequence} = $_[1]; return $_[0]; }
	$_[0]->{sequence};
}
sub pos {
	if(@_ > 1) { $_[0]->{pos} = $_[1]; return $_[0]; }
	$_[0]->{pos};
}
sub hide {
	if(@_ > 1) { $_[0]->{hide} = $_[1]; return $_[0]; }
	$_[0]->{hide};
}
sub flip {
	if(@_ > 1) { $_[0]->{flip} = $_[1]; return $_[0]; }
	$_[0]->{flip};
}
sub all_on_ground { $_[0]->{all_on_ground} }
sub all_folder    { $_[0]->{all_folder} }
sub name          { $_[0]->{name} }
sub to_frame {
	my $self = shift;
	if(@_ > 1) { $self->{to_frame}->set(@_); return $self; }
	$self->{to_frame};
}

###############################################################################
# other

sub move_klaymen_to {
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

sub click_in_rect {
	my ($sprite, @rect) = @_;
	if(my $click = $Cursor->clicked and $rect[2] and $rect[3]) {
		if($ARGV[1]) {
			# my $rect = SDLx::Surface->new(w => $rect[2], h => $rect[3], d => 32, color => 0xFF000000);
			SDL::Video::fill_rect($Games::Neverhood::App, SDL::Rect->new(@rect), SDL::Video::map_RGB($Games::Neverhood::App->format, 255, 0, 0));
		}
		$name = '^idle' if !defined $name and $Game->klaymen;
		if(
			$click->[0] >= $rect[0] and $click->[1] >= $rect[1]
			and $click->[0] < $rect[0] + $rect[2] and $click->[1] < $rect[1] + $rect[3]
			and !defined $name || $Klaymen->sprite =~ /$name/
			and !defined $callback || $Game->call($callback, $sprite, $click)

		) {
			return 1;
		}
	}
	return;
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
 