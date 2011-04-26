package Games::Neverhood::DualVar;
use 5.01;
use warnings;
use strict;
use Carp;
use Scalar::Util;

sub new {
	my $class = shift;
	my $self = bless [], ref $class || $class;
	$self->set(shift // 0, shift // '', @_);
}

sub set {
	if(@_ <= 3) {
		my ($self, $number, $string) = @_;
		if(
			    !defined $number || Scalar::Util::looks_like_number($number)
			and !defined $string || !ref $string
		) {
			$self->[0] = $number + 0  if defined $number;
			$self->[1] = $string . '' if defined $string;
			return $self;
		}
	}
	Carp::confess('arguments: [number, [string]]');
}

use overload
	'""'   => sub { $_[0][1] },
	'0+'   => sub { $_[0][0] },
	
	'+='  => sub { $_[0][0] +=  $_[1]; $_[0] },
	'-='  => sub { $_[0][0] -=  $_[1]; $_[0] },
	'*='  => sub { $_[0][0] *=  $_[1]; $_[0] },
	'/='  => sub { $_[0][0] /=  $_[1]; $_[0] },
	'%='  => sub { $_[0][0] %=  $_[1]; $_[0] },
	'**=' => sub { $_[0][0] **= $_[1]; $_[0] },
	'x='  => sub { $_[0][1] x=  $_[1]; $_[0] },
	'.='  => sub { $_[0][1] .=  $_[1]; $_[0] },
	'<<=' => sub { $_[0][0] <<= $_[1]; $_[0] },
	'>>=' => sub { $_[0][0] >>= $_[1]; $_[0] },
	'&='  => sub { $_[0][0] &=  $_[1]; $_[0] },
	'|='  => sub { $_[0][0] |=  $_[1]; $_[0] },
	'^='  => sub { $_[0][0] ^=  $_[1]; $_[0] },

	'fallback' => 1,
;

1;
