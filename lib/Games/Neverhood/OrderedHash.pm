package Games::Neverhood::OrderedHash;
use Games::Neverhood::OrderedHash::TiedHash;
use Games::Neverhood::OrderedHash::TiedArray;

use 5.01;
use warnings;
use strict;
use Carp;
use Scalar::Util;
use Storable;
use overload
	'%{}' => sub { no overloading; $_[0][0] },
	'@{}' => sub { no overloading; $_[0][1] },

	fallback => 1,
;

sub new {
	my ($class, $order) = (shift, shift);
	if(ref $order eq 'ARRAY') {
		Carp::confess("Order list musn't have dups")
			if keys %{{map {$_ => undef} @$order}} != @$order;
	}
	elsif(!defined $order) {
		$order = [];
	}
	else {
		Carp::confess('First argument must be arrayref or undef');
	}
	my $hash = {};
	$class = ref $class || $class;
	tie my %tie, $class . '::TiedHash',  [$order, $hash];
	tie my @tie, $class . '::TiedArray', [$order, $hash];

	Carp::cluck('Odd number of elements in ordered hash'), push @_, undef
		if @_ % 2;
	for(my $i = 0; $i < @_; $i += 2) {
		$tie{$_[$i]} = $_[$i+1];
	}

	bless [\%tie, \@tie], $class;
}

sub DESTROY {
	no overloading;
	delete $_[0][0];
}

sub STORABLE_freeze {
	my ($self, $cloning) = @_;
	return if $cloning;
	no overloading;
	my $ref = tied(%{$self->[0]});
	Storable::freeze([ $ref->[0], %{$ref->[1]} ]);
}

sub STORABLE_thaw {
	my ($self, $cloning, $serial) = @_;
	return if $cloning;
	no overloading;
	@$self = @{ $self->new(@{ Storable::thaw($serial) }) };
}

1;
