package Games::Neverhood::Holder;
use 5.01;
use strict;
use warnings;

use SDLx::Surface;
use SDL::Image;
use SDL::Video;
use Data::Dumper;

sub new {
	my ($class, %arg) = @_;
	$class = ref $class || $class;
	my $self = bless {}, $class;

	my $sprite = $class;
	$sprite =~ s/::[^:]+$/::Sprite/;
	SPRITE: while((my $name, local $_) = each %arg) {
		for(qw/pos folder sprite hide on_ground/) {
			if($name eq $_) {
				$self->{$_} = $arg{$_};
				delete $arg{$_};
				next SPRITE;
			}
		}
		if(!/=/) { #not blessed
			$arg{$name} = $sprite->_new(
				%$_,
				name   => $name,
				holder => $self,
			);
		}
	}
	die "No sprites for:\n", Dumper $self unless %arg;
	$self->{sprites}  = \%arg;

	$self->{hide}     = 0      unless defined $self->{hide};
	$self->{pos}      = [0, 0] unless defined $self->{pos};
	
	unless(defined $self->{sprite}) {
		($sprite) = keys %{$self->sprites};
		$self->{sprite} = $sprite;
	}

	$self;
}

sub load {
	while(my ($name, $v) = each %{$_[0]->sprites}) {
		warn "No folder for $name" unless defined $v->folder;
		my $path = $Games::Neverhood::M{folder} . '/' . $v->folder . '/' . ($v->name || $name) . '.png';
		$v->surface = SDLx::Surface->new(surface => SDL::Image::load($path) || die($path), flags => SDL_HWSURFACE)
			unless $v->surface =~ /=/;
	}
	$_[0];
}

sub klaymen {
	$_[0] eq $Games::Neverhood::Klaymen;
}

###################################ACCESSORS###################################

sub sprites      :lvalue { $_[0]->{sprites} }
sub sprite_name  :lvalue { $_[0]->{sprite} }
sub sprite       :lvalue { $_[0]->sprites->{$_[0]->sprite_name}}
sub pos          :lvalue { $_[0]->{pos} }
sub hide         :lvalue { $_[0]->{hide} }
sub folder       :lvalue { $_[0]->{folder} }
sub on_ground    :lvalue { $_[0]->{on_ground} }

1;
