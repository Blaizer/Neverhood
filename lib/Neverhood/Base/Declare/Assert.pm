use 5.01;
use strict;
use warnings;

package Neverhood::Base::Declare::Assert;
use parent 'Devel::Declare::Context::Simple';

use Carp qw/croak/;
our @CARP_NOT = 'Devel::Declare';

sub assert ($$) {
	my ($eval, $str) = @_;
	if (!$eval) {
		croak "Error in assert($str): $@" if $@;
		croak "assert($str) failed";
	}
	return;
}

sub parser {
	my $self = shift;
	$self->init(@_);
	my $declarator = $self->declarator;

	my $line = $self->get_linestr;
	$self->skip_declarator;
	$self->skipspace;

	my $pos = $self->offset;
	if (substr($line, $pos, 1) ne "(") {
		croak "Expected ( after $declarator";
	}

	my $len = Devel::Declare::toke_scan_str($pos);
	my $str = Devel::Declare::get_lex_stuff();
	Devel::Declare::clear_lex_stuff();

	substr($line, $pos, $len) = "(eval { $str }, q($str))";
	$self->set_linestr($line);

	$self->shadow(\&assert);

	return;
}

1;
