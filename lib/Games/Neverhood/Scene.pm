package Games::Neverhood::Scene;
use 5.01;
use strict;
use warnings;

sub new {
	my ($class, %arg) = @_;
	for my $holder (@{$arg{holders}}) {
		if($holder !~ /=/) { #not blessed
			$holder = Games::Neverhood::Holder->new(%$holder);
		}
		$holder->folder = $arg{folder} unless defined $holder->folder;
	}
	$arg{cursors} = sub {} unless defined $arg{cursors};
	
	bless \%arg, ref $class || $class;
}

sub set {
	my ($self) = @_;
	$self->load_sprites;
	
	if($self->klaymen) {
		$Games::Neverhood::Klaymen->pos = [$self->klaymen_start, $self->ground];
	}
	
	$Games::Neverhood::App->dt(1 / $self->fps);
	
	$Games::Neverhood::M{scene} = $self;
}

sub load_sprites {
	for(@{$_[0]->holders}) {
		$_->load;
	}
}

sub cursor {
	my @pos = @{$Games::Neverhood::M{mouse}};
	my $cursor = $_[0]->cursors->(@pos);
	$cursor = $Games::Neverhood::Cursors::Default unless defined $cursor;
	return if $cursor eq 0;
	$cursor->pos = \@pos;
	$cursor;
}

sub klaymen {
	grep $_->klaymen, @{$_[0]->holders};
}

###################################ACCESSORS###################################

sub holders        :lvalue { $_[0]->{holders} }
sub cursors        :lvalue { $_[0]->{cursors} }
sub fps            :lvalue { $_[0]->{fps} }
sub klaymen_start  :lvalue { $_[0]->{klaymen_start} }
sub ground         :lvalue { $_[0]->{ground} }


1;
