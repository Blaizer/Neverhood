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
	$arg{cursors}     = sub {} unless defined $arg{cursors};
	$arg{moves}       = sub {} unless defined $arg{moves};
	$arg{events}      = {}     unless defined $arg{events};
	$arg{event_rects} = {}     unless defined $arg{event_rects};
	
	bless \%arg, ref $class || $class;
}

sub set {
	my ($self) = @_;
	$self->load_sprites;
	
	if($self->klaymen) {
		$Games::Neverhood::Klaymen->pos->[1] = $self->ground;
	}
	
	$Games::Neverhood::App->dt(1 / $self->fps);
	
	$Games::Neverhood::M{scene} = $self;
}

sub load_sprites {
	for(@{$_[0]->holders}) {
		$_->load;
	}
}

sub unload_sprites {
	for(@{$_[0]->holders}) {
		$_->unload;
	}
}

sub cursor {
	my @pos = @_ > 1 ? @_ : @{$Games::Neverhood::M{mouse}};
	my ($cursor, $event) = $_[0]->cursors->(@pos);
	$cursor = $Games::Neverhood::Cursor::Default unless defined $cursor;
	$event = 'click' unless defined $event;
	$Games::Neverhood::M{event} = $event;
	return if $cursor eq 0;
	$cursor->pos = \@pos;
	return $cursor;
}

sub klaymen {
	grep $_->klaymen, @{$_[0]->holders};
}

sub cursors_left_right {
	return $Games::Neverhood::Scene::Cursor::Left, 'left' if $_[0] < 320;
	return $Games::Neverhood::Scene::Cursor::Right, 'right';
}
sub cursors_left_forward_right {
	return $Games::Neverhood::Scene::Cursor::Left, 'left' if $_[0] < 100;
	return $Games::Neverhood::Scene::Cursor::Right, 'right' if $_[0] >= 540;
	return $Games::Neverhood::Scene::Cursor::Right, 'forward';
}
sub cursors_out {
	return $Games::Neverhood::Scene::Cursor::Left, 'left' if $_[0] < 10;
	return $Games::Neverhood::Scene::Cursor::Right, 'right' if $_[0] >= 630;
}

sub move {
	$_[0]->moves->(@_);
}

sub rect {
	my ($self, $rect) = @_;
	if(@{$Games::Neverhood::M{click}}) {
		my $click = $Games::Neverhood::M{click}[0];
		$rect = $self->event_rects->{$rect};
		if(
			$click->[0] >= $rect->[0] and $click->[1] >= $rect->[1]
			and $click->[0] < $rect->[0] + $rect->[2] and $click->[1] < $rect->[1] + $rect->[3]
		) {
			return 1;
		}
	}
	return;
}

sub move_to {
	my ($self, $to, $event, $no_shift) = @_;
	
	$Games::Neverhood::M{move_to} = [$to, $event];
	
	$self->shift_click unless $no_shift;
	return;
}

sub shift_click {
	shift @{$Games::Neverhood::M{click}};
}

sub event {
	my $event = pop;
	$_[0]->events->{$event}->(@_);
}

sub sprite {
	die "Must give Scene->sprite an argument" unless @_ > 1;
	for my $holder (@{$_[0]->holders}) {
		for(keys %{$holder->sprites}) {
			return $holder->sprites->{$_} if $_ eq $_[1];
		}
	}
}

###################################ACCESSORS###################################

sub folder      :lvalue { $_[0]->{folder} }
sub fps         :lvalue { $_[0]->{fps} }
sub bounds      :lvalue { $_[0]->{bounds} }
sub ground      :lvalue { $_[0]->{ground} }
sub cursors     :lvalue { $_[0]->{cursors} }
sub events      :lvalue { $_[0]->{events} }
sub event_rects :lvalue { $_[0]->{event_rects} }
sub moves       :lvalue { $_[0]->{moves} }
sub holders     :lvalue { $_[0]->{holders} }

1;
