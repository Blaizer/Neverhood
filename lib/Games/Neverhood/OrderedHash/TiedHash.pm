package Games::Neverhood::OrderedHash::TiedHash;
use 5.01;
use warnings;
use strict;

sub TIEHASH {
	bless $_[1], $_[0];
}
sub FETCH {
	$_[0][1]{$_[1]};
}
sub STORE {
		push @{$_[0][0]}, $_[1]
	unless exists $_[0][1]{$_[1]} or exists ${{ map {$_ => undef} @{$_[0][0]} }}{$_[1]};
	$_[0][1]{$_[1]} = $_[2];
}
sub DELETE {
	delete $_[0][1]{$_[1]};
}
sub CLEAR {
	%{$_[0][1]} = ();
}
sub EXISTS {
	exists $_[0][1]{$_[1]};
}
sub FIRSTKEY {
	keys %{$_[0][1]};
	&NEXTKEY;
}
sub NEXTKEY {
	my $key;
		exists $_[0][1]{$key} and return $key
	while (undef, $key) = each @{$_[0][0]};
	return;
}
sub SCALAR {
	scalar %{$_[0][1]};
}
sub UNTIE {
	Carp::confess('Can not untie ordered hash ties');
}

1;
