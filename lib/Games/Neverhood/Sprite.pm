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

use parent
	'Exporter',
;
use File::Spec ();

# Overloadable Methods:

# sub new
	# name
	# frame
	# sequence
	# pos
	# hide
	# mirror

# use constant
	# sequences
	# dir

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

# sub this_sequence
# sub this_sequence_frame

sub new {
	my ($class, %arg) = @_;
	my $self = bless {}, ref $class || $class;

	my $sprite;
	$self->{sprites} = {};

	while(my ($key, $val) = keys %arg) {
		if($key eq 'sprite') {
			$sprite = $val;
		}
		elsif($key ~~ @All) {
			$self->{$key} = $val;
		}
		else {
			my $self = $self->{sprites}{$key} = {};
			$self->sprite($key);

			$self->{this_sprite}{frames}    = $val->{frames} // 1;
			$self->{this_sprite}{sequences} = $val->{sequences} || [[0]];
			$self->{this_sprite}{offset}[0] //= 0;
			$self->{this_sprite}{offset}[1] //= 0;
			#flipable
			#on_ground

			if(ref $self->events) {
				if(ref $self->events eq 'CODE') {
					$self->events({ 0 => [ true => $self->events ] });
				}
				elsif(ref $self->events eq 'ARRAY') {
					$self->events({ 0 => $self->events });
				}
				elsif(ref $self->events eq 'HASH') {
					for my $k (keys %{$self->events}) {
						my $v = $self->events->{$k};
						$self->events->{$k} = [ true => $v ] if ref $v and ref $v eq 'CODE';
					}
				}
			}
			else {
				$self->events({});
			}
			$self->events({ map { $_ => $self->events->{$_} // [] } 0..$#{$self->sequences} });
			#surface
			#surface_flip
			for(qw/click left right out up down/) {
				if($self->$_ and ref $self->$_ and ref $self->$_ eq 'CODE') {
					$self->$_([ true => $self->$_ ]);
				}
			}
			$self->folder([$self->folder]) if defined $self->folder and !ref $self->folder;
			$self->name($_) unless defined $self->name;
		}
	}

	$self->{to_frame} = Games::Neverhood::DualVar->new;
	$self->frame($self->frame // 0);
	$self->sequence(0) unless defined $self->sequence;
	$self->pos([]) unless defined $self->pos;
	$self->pos->[0] //= 0;
	$self->pos->[1] //= 0;
	#hide
	#flip
	#global
	#all_on_ground
	#all_folder
	;#all_name

	$self->sprite($sprite) if defined $sprite;
	$self;
}

###############################################################################

sub show {
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

sub load {
	my ($self) = @_;
	for my $name (keys %{$self->sprites}) {
		my $s_s = $self->sprites->{$name};
		my $folder;
		die "No folder for $name" unless defined($folder = $s_s->{folder} // $self->all_folder);
		my $path = File::Spec->catfile($Games::Neverhood::Folder, @$folder, "$name.png");
		$s_s->{surface} = SDL::Image::load($path) or die SDL::get_error;
		if($s_s->{flipable}) {
			$s_s->{surface_flip} = SDL::GFX::Rotozoom::zoom_surface($s_s->{surface}, -1, 1, 0);
		}
	}
	$self;
}

sub set {
	my ($self, $name, $frame, $sequence) = @_;
	$self->sprite($name) if defined $name;
	$self->frame($frame || 0);
	$self->sequence($sequence || 0);
}

sub get {
	my ($self, $name, $frame, $sequence) = @_;
		!defined $name     || $self->sprite eq $name
	and !defined $frame    || ($frame eq 'end' ? $self->to_frame eq 'end' : $self->to_frame == $frame)
	and !defined $sequence || $self->sequence == $sequence
}

sub move_to {
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

sub rect {
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

# our @Callback;
# SDL::Mixer::Channels::channel_finished(sub {
	# my ($channel) = @_;
	# if(defined $Callback[$channel]) {
		# &{$Callback[$channel]};
		# delete $Callback[$channel];
	# }
# });

sub play_sound {
	shift;
	my %arg;
	if(@_ == 1) {
		($arg{name}) = @_;
	}
	else {
		%arg = @_;
	}
	my $name = File::Spec->catfile($Games::Neverhood::Folder, 'sound', (ref $arg{name} ? @{$arg{name}} : $arg{name}) . '.ogg');
	my $chunk = SDL::Mixer::Samples::load_WAV($name) or die "Could not load $name ", SDL::get_error;
	my $channel = SDL::Mixer::Channels::play_channel(-1, $chunk, $arg{loops} // 0);
	SDL::Mixer::Channels::volume($channel, $arg{volume}) if defined $arg{volume};
	# $Callback[$channel] = $arg{callback} if defined $arg{callback};
	$channel;
}

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

sub sequences    { $_[0]->{this_sprite}{sequences} }
sub offset       { $_[0]->{this_sprite}{offset} }
sub on_ground    { $_[0]->{this_sprite}{on_ground} // $_[0]->all_on_ground }
sub events       { $_[0]->{this_sprite}{events} }
sub on_click     {
		$_[0]->{this_sprite}{on_click}[0]->($_[0]) and
		$_[0]->{this_sprite}{on_click}[1]->($_[0])
	if $_[0]->{this_sprite}{on_click};
}
sub folder       { $_[0]->{this_sprite}{folder} // $_[0]->all_folder }

sub this_sequence       { $_[0]->sequences($_[0]->sequence) }
sub this_sequence_frame { $_[0]->this_sequence($_[0]->frame) }
sub events_sequence     { $_[0]->events($_[0]->sequence) }

1;
 