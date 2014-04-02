# modified from Method::Signatures::Simple 1.07

use 5.01;
use strict;
use warnings;

package Neverhood::Base::Declare::SubSignatures;
use parent 'Devel::Declare::MethodInstaller::Simple';

sub parse_proto {
	my $self = shift;
	my ($proto) = @_;
	$proto //= '';
	my $invocant     = $self->{invocant};
	my $pre_invocant = $self->{pre_invocant};

	$proto =~ s/\s+//g;
	$invocant = $1 if $invocant and $proto =~ s{^(\$\w+):}//;

	my $inject = '';
	$inject .= "my $pre_invocant = shift;" if $pre_invocant;
	$inject .= "my $invocant = shift;"     if $invocant;
	$inject .= "my ($proto) = \@_;"        if length $proto;
	$inject .= "();"; # fix for empty method body

	return $inject;
}

1;
