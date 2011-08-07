package Games::Neverhood::OrderedHash::TiedHash;
use Games::Neverhood::OrderedHash qw/ORDER HASH/;

use 5.01;
use warnings;
use strict;
use Carp;

sub TIEHASH {
	bless $_[1], $_[0];
}

sub FETCH {
	my ($self, $key) = @_;
	$self->[HASH]{$key};
}
sub STORE {
	my ($self, $key, $value) = @_;
	# if key is not in Order, push it in
	unless(
		exists $self->[HASH]{$key}
		or exists { map {$_ => undef} @{$self->[ORDER]} }->{$key}
	) {
		push @{$self->[ORDER]}, $key
	}
	$self->[HASH]{$key} = $value;
}
sub DELETE {
	my ($self, $key) = @_;
	delete $self->[HASH]{$key};
}
sub CLEAR {
	my ($self) = @_;
	%{$self->[HASH]} = ();
}
sub EXISTS {
	my ($self, $key) = @_;
	exists $self->[HASH]{$key};
}
sub FIRSTKEY {
	my ($self) = @_;
	keys %{$self->[HASH]};
	&NEXTKEY;
}
sub NEXTKEY {
	my ($self) = @_;
	my $key;
	while((undef, $key) = each @{$self->[ORDER]}) {
		exists $self->[HASH]{$key} and return $key
	}
	return;
}
sub SCALAR {
	my ($self) = @_;
	scalar %{$self->[HASH]};
}
sub UNTIE {
	Carp::confess('Can not untie ordered hash ties');
}

1;
