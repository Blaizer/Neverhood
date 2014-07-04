use 5.01;
use strict;
use warnings;

package Neverhood::Base::Declare::Modifier;
use parent 'Devel::Declare::Context::Simple';

use Carp qw/croak/;
our @CARP_NOT = 'Devel::Declare';

sub parser {
	# parses
	# before foo ($this: $foo, $bar) { ... }
	# into
	# before "foo", method ($this: $foo, $bar) { ... };

	my $self = shift;
	$self->init(@_);
	my $declarator = $self->declarator;

	my $line = $self->get_linestr;
	$self->skip_declarator;
	$self->skipspace;
	my $start_pos = $self->offset;

	my $pos = $self->offset;
	my $name;
	my $len;
	if (substr($line, $pos, 1) eq "[") {
		$len  = Devel::Declare::toke_scan_str($pos);
		$name = Devel::Declare::get_lex_stuff();
		Devel::Declare::clear_lex_stuff();
		$name = "[$name]";
	}
	else {
		$len = Devel::Declare::toke_scan_word($pos, 0);
		if ($len) {
			$name = substr($line, $pos, $len);
			$name = qq/"$name"/;
		}
	}

	$self->inc_offset($len);
	$self->skipspace;
	my $proto = $self->strip_proto // '';
	$self->skipspace;
	$line = $self->get_linestr;
	$pos = $self->offset;
	substr($line, $pos++, 1) eq '{' or croak "Illegal $declarator definition";

	my $sub = $self->{sub};
	my $insert = "$name, $sub ($proto) { ";
	$insert .= $self->scope_injector_call if defined $name;
	substr($line, $start_pos, $pos - $start_pos) = $insert;
	$self->set_linestr($line);

	return;
}

1;
