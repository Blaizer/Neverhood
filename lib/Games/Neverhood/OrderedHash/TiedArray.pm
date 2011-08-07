package Games::Neverhood::OrderedHash::TiedArray;
use Games::Neverhood::OrderedHash qw/ORDER HASH/;

use 5.01;
use warnings;
use strict;
use Carp;

*TIEARRAY = \&Games::Neverhood::OrderedHash::TiedHash::TIEHASH;

sub FETCH {
	my ($self, $index) = @_;
		return $self->[HASH]{$self->[ORDER][$index]}
	if $index < @{$self->[ORDER]};
	return;
}
sub STORE {
	my ($self, $index, $value) = @_;
		return $self->[HASH]{$self->[ORDER][$index]} = $value
	if $index < @{$self->[ORDER]};
	Carp::confess("Modification of ordered hash index $index with no corresponding key");
}
sub FETCHSIZE {
	my ($self) = @_;
	scalar @{$self->[ORDER]};
}
sub STORESIZE {}
sub EXTEND {}
sub EXISTS {
	my ($self, $index) = @_;
		return exists $self->[HASH]{$self->[ORDER][$index]}
	if $index < @{$self->[ORDER]};
	return;
}
sub DELETE {
	my ($self, $index) = @_;
		return delete $self->[HASH]{$self->[ORDER][$index]}
	if $index < @{$self->[ORDER]};
	return;
}
*CLEAR = \&Games::Neverhood::OrderedHash::TiedHash::CLEAR;
sub POP {
	my ($self) = @_;
		return delete $self->[HASH]{pop @{$self->[ORDER]}}
	if @{$self->[ORDER]};
	return;
}
sub SHIFT {
	my ($self) = @_;
		return delete $self->[HASH]{shift @{$self->[ORDER]}}
	if @{$self->[ORDER]};
	return;
}
sub SPLICE {
	my ($self) = shift;
	@_ > 2 and Carp::confess("Supplying a replacement list in splice is illegal");

	my @deleted;
	for(splice @{$self->[ORDER]}, @_) {
		push @deleted, delete $self->[HASH]{$_};
	}
	return wantarray ? @deleted : pop @deleted;
}
sub PUSH {
	Carp::confess("Pushing or unshifting an ordered hash is illegal");
}
*UNSHIFT = \&PUSH;
*UNTIE = \&Games::Neverhood::OrderedHash::TiedHash::UNTIE;

1;
