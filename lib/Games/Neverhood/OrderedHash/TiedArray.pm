package Games::Neverhood::OrderedHash::TiedArray;
use Games::Neverhood::OrderedHash::TiedHash;
use 5.01;
use warnings;
use strict;

sub TIEARRAY {
	bless $_[1], $_[0];
}
sub FETCH {
		return $_[0][1]{$_[0][0][$_[1]]}
	if $_[1] < @{$_[0][0]};
	return;
}
sub STORE {
		return $_[0][1]{$_[0][0][$_[1]]} = $_[2]
	if $_[1] < @{$_[0][0]};
	Carp::confess("Modification of ordered hash index $_[1] with no corresponding key");
}
sub FETCHSIZE {
	scalar @{$_[0][0]};
}
sub STORESIZE {}
sub EXTEND {}
sub EXISTS {
		return exists $_[0][1]{$_[0][0][$_[1]]}
	if $_[1] < @{$_[0][0]};
	return;
}
sub DELETE {
		return delete $_[0][1]{$_[0][0][$_[1]]}
	if $_[1] < @{$_[0][0]};
	return;
}
*CLEAR = \&Games::Neverhood::OrderedHash::TiedHash::CLEAR;
sub POP {
	my $pop;
		$pop = $_[0][1]{$_[0][0][-1]},
		delete $_[0][1]{pop @{$_[0][0]}},
		return $pop
	if @{$_[0][0]};
	return;
}
sub SHIFT {
	my $shift;
		$shift = $_[0][1]{$_[0][0][0]},
		delete $_[0][1]{shift @{$_[0][0]}},
		return $shift
	if @{$_[0][0]};
	return;
}
sub SPLICE {
	my $self = shift;
	Carp::confess("Supplying a replacement list in splice is illegal") if @_ > 2;
	my @deleted;
	for(splice @{$self->[0]}, @_) {
		push @deleted, $self->[1]{$_};
		delete $self->[1]{$_};
	}
	return wantarray ? @deleted : pop @deleted;
}
sub PUSH {
	Carp::confess("Pushing or unshifting an ordered hash is illegal");
}
*UNSHIFT = \&PUSH;
*UNTIE = \&Games::Neverhood::OrderedHash::TiedHash::UNTIE;

1;
