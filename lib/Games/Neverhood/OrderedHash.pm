use 5.01;
use warnings;
use strict;
package Games::Neverhood::OrderedHash;

use Carp;
use Storable;

use constant {
	TIEDHASH  => 0,
	TIEDARRAY => 1,
	ORDER     => 0,
	HASH      => 1,
};
use parent "Exporter";
BEGIN {
	our @EXPORT_OK = (qw/TIEDHASH TIEDARRAY ORDER HASH/);
}
use Games::Neverhood::OrderedHash::TiedHash;
use Games::Neverhood::OrderedHash::TiedArray;

use overload
	'%{}' => sub { no overloading; $_[0][TIEDHASH] },
	'@{}' => sub { no overloading; $_[0][TIEDARRAY] },

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
	# The two ties must share the same order and hash, but must use unique arrayrefs for destruction to work correctly
	tie my %tie, 'Games::Neverhood::OrderedHash::TiedHash',  [$order, $hash];
	tie my @tie, 'Games::Neverhood::OrderedHash::TiedArray', [$order, $hash];

	Carp::cluck('Odd number of elements in ordered hash'), push @_, undef
		if @_ % 2;
	for(my $i = 0; $i < @_; $i += 2) {
		$tie{$_[$i]} = $_[$i+1];
	}

	bless [\%tie, \@tie], $class;
}
sub DESTROY {
	my ($self) = @_;
	no overloading;
	# delete the tiedhash to break reference loop
	delete $self->[TIEDHASH];
}

sub STORABLE_freeze {
	my ($self, $cloning) = @_;
	return if $cloning;
	no overloading;
	my $ref = tied(%{$self->[TIEDHASH]});
	Storable::freeze([ $ref->[ORDER], %{$ref->[HASH]} ]);
}
sub STORABLE_thaw {
	my ($self, $cloning, $serial) = @_;
	return if $cloning;
	no overloading;
	@$self = @{ $self->new(@{ Storable::thaw($serial) }) };
}

1;
