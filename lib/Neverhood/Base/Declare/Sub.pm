# modified from Method::Signatures::Simple 1.07

use 5.01;
use strict;
use warnings;

package Neverhood::Base::Declare::Sub;
use parent 'Devel::Declare::Context::Simple';

sub block () {}
sub expression ($) { $_[0] }

sub parser {
	my $self = shift;
	$self->init(@_);

	my $declarator = $self->declarator;
	$self->skip_declarator;

	my $name   = $self->strip_name;
	my $proto  = $self->strip_proto // '';
	my $attrs  = $self->strip_attrs // '';
	my $inject = $self->parse_proto($proto);
	$inject  .= "();"; # fix for empty sub body

	if (defined $name) {
		$self->inject_if_block($inject, ";sub $name $attrs");
		$self->shadow(\&block);
	}
	else {
		$self->inject_if_block($inject, "sub $attrs");
		$self->shadow(\&expression);
	}

	return;
}

sub parse_proto {
	my $self = shift;
	my ($proto) = @_;
	my $invocant     = $self->{invocant};
	my $pre_invocant = $self->{pre_invocant};

	$proto =~ s/\s+//g;
	$invocant = $1 if $invocant and $proto =~ s{^(\$\w+):}//;

	my $inject = '';
	$inject .= "my $pre_invocant = shift;" if $pre_invocant;
	$inject .= "my $invocant = shift;"     if $invocant;
	$inject .= "my ($proto) = \@_;"        if length $proto;

	return $inject;
}

1;
