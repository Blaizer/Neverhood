use 5.01;
use strict;
use warnings;

package Neverhood::Base::Declare::Package;
use parent 'Devel::Declare::Context::Simple';

use Carp qw/croak/;
our @CARP_NOT = 'Devel::Declare';

use B::Hooks::EndOfScope;

# keeps track of nested package blocks to prefix the inner package names with the outer names
our @_prefix = '';

sub package () {}

sub parser {
	# parses
	# class Foo::Bar {
		# ...
	# }
	# into
	# class; {
		# package Foo::Bar;
		# use Neverhood::Base ':class';
		# {
			# ...
			# no Neverhood::Base;
			# Foo::Bar->meta->make_immutable;
		# }
		# 1;
	# }

	my $self = shift;
	$self->init(@_);
	my $declarator = $self->declarator;

	my $line = $self->get_linestr;
	$self->skip_declarator;
	my $start_pos = $self->offset;
	$self->skipspace;

	my $pos = $self->offset;
	my $len = Devel::Declare::toke_scan_ident($self->offset); # identifier
	$len or croak "Expected word after $declarator";
	my $package = substr($line, $pos, $len);

	$self->inc_offset($len);
	$self->skipspace;
	$pos = $self->offset;
	my $c = substr($line, $pos++, 1);

	if ($c ne '{') {
		croak "Illegal $declarator definition";
	}

	$package = $_prefix[-1] . $package;
	push @_prefix, $package . '::';

	my $make_immutable = $self->{make_immutable};
	my $insert = '';
	$insert .= ";{ package $package; { use Neverhood::Base ':$declarator';";
	$insert .= qq(BEGIN { Neverhood::Base::Declare::Package::on_package_end("$package", $make_immutable) });
	substr($line, $start_pos, $pos - $start_pos) = $insert;
	$self->set_linestr($line);

	$self->shadow(\&package);

	return;
}

sub on_package_end {
	my ($package, $make_immutable) = @_;
	on_scope_end {
		my $line = Devel::Declare::get_linestr;
		my $pos = Devel::Declare::get_linestr_offset;
		my $insert =  "no Neverhood::Base;";
		$insert .= "$package->meta->make_immutable;" if $make_immutable;
		$insert .= 'BEGIN { pop @Neverhood::Base::Declare::Package::_prefix }';
		$insert .= "0 }";
		substr($line, $pos, 0) = $insert;
		Devel::Declare::set_linestr $line;
	}
}

1;
