package Games::Neverhood::Scene;
use 5.01;
use strict;
use warnings;

use Data::Dumper;

#sprites all_folder fps bounds cursors setup setdown

sub new {
	my ($class, %arg) = @_;
	my $self = bless \%arg, ref $class || $class;
	
	$self->all_folder([$self->all_folder]) if defined $self->all_folder and !ref $self->all_folder;
	for my $sprite (@{$self->sprites}) {
		if($sprite !~ /=/) { #not blessed
			$sprite = Games::Neverhood::Sprite->new(%$sprite);
			$sprite->all_folder($self->all_folder) if defined $self->all_folder and !defined $sprite->all_folder;
		}
		else {
			next if $sprite->global;
			$sprite->global(1);
		}
		$sprite->load;
	}
	$self->fps(24)         unless defined $self->fps;
	#bounds
	$self->cursors(sub {}) unless defined $self->cursors;
	$self->setup(sub {})   unless defined $self->setup;
	$self->setdown(sub {}) unless defined $self->setdown;

	$self;
}

sub set {
	no strict 'refs';
	my ($unset_123, $set_2, $set_3) = @_;
	my ($unset_23) = $unset_123 =~ /^Games::Neverhood::Scene::(.*)/;
	$set_3 //= '';
	my $set_12 = "Games::Neverhood::Scene::$set_2";
	my $arg = {
		set     => $set_2 . $set_3,
		klaymen => $Games::Neverhood::Klaymen,
	};
	
	${$unset_123}->setdown->(${$unset_123}, $arg);
	undef ${$unset_123};
	
	eval "use $set_12 '$set_3'";
	my $self = ${$set_12 . $set_3};
	$Games::Neverhood::Scene = $self;
	delete $arg->{set};
	$arg->{unset} = $unset_23;
	$self->setup->($self, $arg);
	
	$Games::Neverhood::App->dt(1 / $self->fps);
	$self;
}

sub cursors_left_right {
	return 'left', 'left' if $_[0] < 320;
	return 'right', 'right';
}
sub cursors_left_forward_right {
	my $range = 100;
	return 'left', 'left' if $_[0] < $range;
	return 'right', 'right' if $_[0] >= 640 - $range;
	return 'forward', 'forward';
}
sub cursors_out {
	my $range = 20;
	return 'left', 'out' if $_[0] < $range;
	return 'right', 'out' if $_[0] >= 640 - $range;
	return;
}

sub delete_clicked {
	$Games::Neverhood::Cursor->clicked(undef);
}

sub klaymen {
	for(@{$_[0]->sprites}) {
		return $Games::Neverhood::Klaymen if $_ == $Games::Neverhood::Klaymen;
	}
}
sub sprite {
	$_[1] ~~ $_[0]->sprites;
}

sub call {
	my (undef, $callback, @arg) = @_;
	$callback->(@arg);
}

###################################ACCESSORS###################################
sub sprites {
	if(@_ > 1) { $_[0]->{sprites} = $_[1]; return $_[0]; }
	$_[0]->{sprites};
}
sub all_folder {
	if(@_ > 1) { $_[0]->{all_folder} = $_[1]; return $_[0]; }
	$_[0]->{all_folder};
}
sub fps {
	if(@_ > 1) { $_[0]->{fps} = $_[1]; return $_[0]; }
	$_[0]->{fps};
}
sub bounds {
	if(@_ > 1) { $_[0]->{bounds} = $_[1]; return $_[0]; }
	$_[0]->{bounds};
}
sub cursors {
	if(@_ > 1) { $_[0]->{cursors} = $_[1]; return $_[0]; }
	$_[0]->{cursors};
}
sub setup {
	if(@_ > 1) { $_[0]->{setup} = $_[1]; return $_[0]; }
	$_[0]->{setup};
}
sub setdown {
	if(@_ > 1) { $_[0]->{setdown} = $_[1]; return $_[0]; }
	$_[0]->{setdown};
}

1;
