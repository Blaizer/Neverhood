package Games::Neverhood::Sprite;
use 5.01;
use strict;
use warnings;

use SDL::Image;
use SDL::Video;
use SDL::Rect;
use SDL::GFX::Rotozoom;
use Data::Dumper;
use File::Spec;
use Scalar::Util qw/dualvar/;

#ALL
#sprites sprite frame sequence pos hide flip global all_on_ground all_folder all_name
#to_frame
#sprites_sprite

#SPRITE
#frames sequences offset flipable on_ground events surface surface_flip click left right out up down folder name
#this_sequence this_sequence_frame events_sequence

sub new {
	my ($class, %arg) = @_;
	my $self = bless {}, ref $class || $class;
	
	my $sprite;
	if(defined $arg{sprite}) {
		$sprite = $arg{sprite};
		delete $arg{sprite};
	}
	for(keys %arg) {
		if($_ ~~ [qw/frame sequence pos hide flip all_on_ground all_folder all_name/]) {
			$self->$_($arg{$_});
			delete $arg{$_};
		}
	}
	$self->frame($self->frame // 0);
	$self->sequence(0) unless defined $self->sequence;
	$self->pos([]) unless defined $self->pos;
	$self->pos->[0] //= 0;
	$self->pos->[1] //= 0;
	#hide
	#flip
	#global
	#all_on_ground
	$self->all_folder([$self->all_folder]) if defined $self->all_folder and !ref $self->all_folder;
	#all_name
	#to_frame
	
	$self->sprites(\%arg);
	for(keys %arg) {
		$self->sprite($_);
		
		$self->frames(1) unless defined $self->frames;
		$self->sequences([[0]]) unless defined $self->sequences;
		$self->sequences([$self->sequences]) if ref $self->sequences->[0] ne 'ARRAY';
		$self->offset([]) unless defined $self->offset;
		$self->offset->[0] //= 0;
		$self->offset->[1] //= 0;
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
	die "No sprites for one of them" unless %arg;

	$self->sprite($sprite) if defined $sprite;
	$self;
}

###############################################################################

sub show {
	my ($self) = @_;
	return if $self->hide;
	my $surface = $self->this_surface;
	die 'no surface', $self->flip ? '_flip' : '', ' for: ', $self->folder, '/', $self->name unless ref $surface;
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
	$Games::Neverhood::Klaymen->moving_to({
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
	my @rect;
	(my $sprite, @rect[0..3], my $name, my $callback) = @_;
	if(my $click = $Games::Neverhood::Cursor->clicked and $rect[2] and $rect[3]) {
		if($ARGV[1]) {
			# my $rect = SDLx::Surface->new(w => $rect[2], h => $rect[3], d => 32, color => 0xFF000000);
			SDL::Video::fill_rect($Games::Neverhood::App, SDL::Rect->new(@rect), SDL::Video::map_RGB($Games::Neverhood::App->format, 255, 0, 0));
		}
		$name = '^idle' if !defined $name and $Games::Neverhood::Scene->klaymen;
		if(
			$click->[0] >= $rect[0] and $click->[1] >= $rect[1]
			and $click->[0] < $rect[0] + $rect[2] and $click->[1] < $rect[1] + $rect[3]
			and !defined $name || $Games::Neverhood::Klaymen->sprite =~ /$name/
			and !defined $callback || Games::Neverhood::Scene->call($callback, $sprite, {
				click => $click,
				klaymen => $Games::Neverhood::Klaymen
			})

		) {
			return 1;
		}
	}
	return;
}

###############################################################################

sub sprites {
	if(@_ > 1) { $_[0]->{sprites} = $_[1]; return $_[0]; }
	$_[0]->{sprites};
}
sub sprite {
	if(@_ > 1) {
		die 'sprite $_[1] was set and does not exist' unless defined $_[0]->sprites->{$_[1]};
		$_[0]->{sprite} = $_[1];
		$_[0]->{this_sprite} = $_[0]->sprites->{$_[1]};
		return $_[0];
	}
	$_[0]->{sprite};
}
sub frame :lvalue {
	if(@_ > 1) {
		$_[0]->{frame} = $_[1] + $Games::Neverhood::Remainder;
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
sub global {
	if(@_ > 1) { $_[0]->{global} = $_[1]; return $_[0]; }
	$_[0]->{global};
}
sub all_on_ground {
	if(@_ > 1) { $_[0]->{all_on_ground} = $_[1]; return $_[0]; }
	$_[0]->{all_on_ground};
}
sub all_folder {
	if(@_ > 1) { $_[0]->{all_folder} = $_[1]; return $_[0]; }
	$_[0]->{all_folder};
}
# sub all_name {
	# if(@_ > 1) { $_[0]->{all_name} = $_[1]; return $_[0]; }
	# $_[0]->{all_name};
# }
sub to_frame {
	$_[0]->{to_frame} = dualvar $_[1], $_[2] if @_ > 1;
	$_[0]->{to_frame};
}

###############################################################################

sub frames {
	if(@_ > 1) { $_[0]->{this_sprite}{frames} = $_[1]; return $_[0]; }
	$_[0]->{this_sprite}{frames};
}
sub sequences {
	if(@_ > 1) { $_[0]->{this_sprite}{sequences} = $_[1]; return $_[0]; }
	$_[0]->{this_sprite}{sequences};
}
sub offset {
	if(@_ > 1) { $_[0]->{this_sprite}{offset} = $_[1]; return $_[0]; }
	$_[0]->{this_sprite}{offset};
}
sub flipable {
	if(@_ > 1) { $_[0]->{this_sprite}{flipable} = $_[1]; return $_[0]; }
	$_[0]->{this_sprite}{flipable};
}
sub on_ground {
	if(@_ > 1) { $_[0]->{this_sprite}{on_ground} = $_[1]; return $_[0]; }
	$_[0]->{this_sprite}{on_ground} // $_[0]->all_on_ground;
}
sub events {
	if(@_ > 1) { $_[0]->{this_sprite}{events} = $_[1]; return $_[0]; }
	$_[0]->{this_sprite}{events};
}
sub surface {
	if(@_ > 1) { $_[0]->{this_sprite}{surface} = $_[1]; return $_[0]; }
	$_[0]->{this_sprite}{surface};
}
sub surface_flip {
	if(@_ > 1) { $_[0]->{this_sprite}{surface_flip} = $_[1]; return $_[0]; }
	$_[0]->{this_sprite}{surface_flip};
}
sub click {
	if(@_ > 1) { $_[0]->{this_sprite}{click} = $_[1]; return $_[0]; }
	$_[0]->{this_sprite}{click};
}
sub left {
	if(@_ > 1) { $_[0]->{this_sprite}{left} = $_[1]; return $_[0]; }
	$_[0]->{this_sprite}{left};
}
sub right  {
	if(@_ > 1) { $_[0]->{this_sprite}{right} = $_[1]; return $_[0]; }
	$_[0]->{this_sprite}{right};
}
sub out {
	if(@_ > 1) { $_[0]->{this_sprite}{out} = $_[1]; return $_[0]; }
	$_[0]->{this_sprite}{out};
}
sub up {
	if(@_ > 1) { $_[0]->{this_sprite}{up} = $_[1]; return $_[0]; }
	$_[0]->{this_sprite}{up};
}
sub down {
	if(@_ > 1) { $_[0]->{this_sprite}{down} = $_[1]; return $_[0]; }
	$_[0]->{this_sprite}{down};
}
sub folder {
	if(@_ > 1) { $_[0]->{this_sprite}{folder} = $_[1]; return $_[0]; }
	$_[0]->{this_sprite}{folder} // $_[0]->all_folder;
}
sub name {
	if(@_ > 1) { $_[0]->{this_sprite}{name} = $_[1]; return $_[0]; }
	$_[0]->{this_sprite}{name};
}

sub this_sequence       { $_[0]->sequences->[$_[0]->sequence] }
sub this_sequence_frame { $_[0]->this_sequence->[$_[0]->frame] }
sub events_sequence     { $_[0]->events->{$_[0]->sequence} }
sub this_surface        { $_[0]->flip ? $_[0]->surface_flip : $_[0]->surface }

1;
