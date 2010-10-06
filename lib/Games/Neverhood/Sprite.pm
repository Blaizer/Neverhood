package Games::Neverhood::Sprite;
use 5.01;
use strict;
use warnings;

use Data::Dumper;

sub _new {
	my ($class, $s) = (shift, {@_});
	$s->{offset}    = [0, 0] unless defined $s->{offset};
	$s->{frames}    = 1      unless defined $s->{frames};
	$s->{sequences} = [[0]]  unless defined $s->{sequences};
	$s->{surface}   = \0     unless defined $s->{surface};
	$s->{sequence}  = 0      unless defined $s->{sequence};
	$s->{frame}     = 0      unless defined $s->{frame};
	if(ref $s->{events} and ref $s->{events} eq 'CODE') {
		$s->{events} = { 0 => $s->{events} };
	}
	$s->{events} = { map { $_, $s->{events}{$_} || sub {} } 0..$#{$s->{sequences}} };

	bless $s, ref $class || $class;
}

sub show {
	my ($self) = @_;
	return if $self->hide;
	my $surface = $self->flip ? $self->surface_flip : $self->surface;$surface || die Dumper $self;
	my $h = $surface->h / $self->frames;
	$surface->blit(
		$Games::Neverhood::App,
		[0, $h * $self->sequence_frame, $surface->w, $h],
		[
			$self->pos->[0] + 
				($self->flip
				? -$surface->w - $self->offset->[0] + 1
				: $self->offset->[0]),
				($self->on_ground
				? 480 - $self->pos->[1] + $self->offset->[1] - $h
				: $self->pos->[1] + $self->offset->[1])
		]
	);
}

sub klaymen {
	$_[0]->holder->klaymen;
}

sub DESTROY {
	delete $_[0]->{holder}; #break reference circle
}



###################################ACCESSORS###################################

sub folder          :lvalue { defined $_[0]->{folder} ? $_[0]->{folder} : $_[0]->holder->folder }
sub offset          :lvalue { $_[0]->{offset} }
sub frames          :lvalue { $_[0]->{frames} }
sub sequences       :lvalue { $_[0]->{sequences} }
sub surface         :lvalue { $_[0]->{surface} }
sub surface_flip    :lvalue { $_[0]->{surface_flip} }
sub holder          :lvalue { $_[0]->{holder} }
sub pos             :lvalue { $_[0]->holder->pos }
sub hide            :lvalue { $_[0]->holder->hide }
sub frame           :lvalue { $_[0]->{frame} }
sub frame_remainder         { $_[0]->frame - int $_[0]->frame }
sub sequence_num    :lvalue { $_[0]->{sequence} }
sub sequence        :lvalue { $_[0]->sequences->[$_[0]->sequence_num] }
sub sequence_frame  :lvalue { $_[0]->sequence->[$_[0]->frame] }
sub name            :lvalue { $_[0]->{name} }
sub events          :lvalue { $_[0]->{events} }
sub events_sequence :lvalue { $_[0]->events->{$_[0]->sequence_num} }
sub sprite_name     :lvalue { $_[0]->holder->sprite_name }
sub on_ground       :lvalue { defined $_[0]->{on_ground} ? $_[0]->{on_ground} : $_[0]->holder->on_ground }
sub flipable        :lvalue { $_[0]->{flipable} }
sub flip                    { shift->holder->flip(@_) }

1;
