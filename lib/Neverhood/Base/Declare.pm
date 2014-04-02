use 5.01;
use strict;
use warnings;

package Neverhood::Base::Declare;
use Devel::Declare;
use parent 'Devel::Declare::Context::Simple';

use Carp qw/croak/;
our @CARP_NOT = 'Devel::Declare';
use Symbol;
use Sub::Name;

use B::Hooks::EndOfScope;
use Mouse::Exporter ();
use Neverhood::Base::Declare::SubSignatures;

Mouse::Exporter->setup_import_methods(
	as_is => [
		qw/ trigger build class role assert /,
	],
);

sub assert ($$) {
	my ($eval, $str) = @_;
	if (!$eval) {
		if ($@) {
			croak "Error in assert($str): $@";
		}
		else {
			croak "assert($str) failed";
		}
	}
	return;
}

sub class () {}
sub role  () {}

sub _attribute_modifier {
	my ($declarator, $names, $sub) = @_;
	my $caller = caller;

	if (!defined $names) {
		return $declarator => $sub;
	}

	my @names = ref $names eq "ARRAY" ? @$names : $names;
	my $sub_name = uc($declarator) . "_" . join "__", @names;
	my $qualified_name = qualify $sub_name, $caller;
	my $ref = qualify_to_ref $qualified_name;
	*$ref = subname $qualified_name, $sub;

	if ($declarator eq "trigger") {
		for my $name (@names) {
			$caller->meta->add_attribute("+$name", trigger => \&$ref);
		}
	}
	elsif ($declarator eq "build") {
		for my $name (@names) {
			$caller->meta->add_attribute("+$name", builder => \&$ref);
		}
	}
}

sub trigger {
	unshift @_, "trigger";
	goto \&_attribute_modifier;
}
sub build {
	unshift @_, "build";
	goto \&_attribute_modifier;
}
sub set {
	unshift @_, "set";
	goto \&_attribute_modifier;
}

sub setup_declarators {
	my ($class, $caller) = @_;
	$caller //= scalar caller;
	my $ctx = $class->new;
	my $warnings = warnings::enabled("redefine");

	my $signature = sub {
		my $name = shift;
		my $ctx = Neverhood::Base::Declare::SubSignatures->new(
			into => $caller,
			name => $name,
			@_,
		);
		return $name => { const => sub { $ctx->parser(@_, $warnings) } };
	};

	Devel::Declare->setup_for(
		$caller,
		{
			$signature->( func    => () ),
			$signature->( method  => ( invocant => '$self' ) ),
			$signature->( _around => ( invocant => '$self', pre_invocant => '$orig' ) ),
			before  => { const => sub { $ctx->method_modifier_parser(@_) } },
			after   => { const => sub { $ctx->method_modifier_parser(@_) } },
			around  => { const => sub { $ctx->method_modifier_parser(@_) } },
			trigger => { const => sub { $ctx->method_modifier_parser(@_) } },
			build   => { const => sub { $ctx->method_modifier_parser(@_) } },

			class => { const => sub { $ctx->class_or_role_parser(@_) } },
			role  => { const => sub { $ctx->class_or_role_parser(@_) } },

			assert => { const => sub { $ctx->assert_parser(@_) } },
		},
	);
}

sub teardown_declarators {
	my ($class, $caller) = @_;
	$caller //= scalar caller;
	Devel::Declare->teardown_for($caller);
}

sub method_modifier_parser {
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
	my $proto = $self->strip_proto;
	$proto //= '$new, $old' if $declarator eq "trigger";
	$proto //= '';
	$self->skipspace;
	$line = $self->get_linestr;
	$pos = $self->offset;
	substr($line, $pos++, 1) eq '{' or croak "Illegal $declarator definition";

	my $keyword =
		$declarator eq "around" || $declarator eq "set" ? "_around" : "method";
	my $insert = "$name, $keyword ($proto) { ";
	$insert .= $self->scope_injector_call if defined $name;
	substr($line, $start_pos, $pos - $start_pos) = $insert;
	$self->set_linestr($line);

	return;
}

sub trigger_or_builder_parser {
	# parses
	# trigger foo { ... }
	# into
	# trigger "foo", method ($new, $old) { ... };

	# or
	# trigger { ... };
	# into
	# trigger undef, method ($new, $old) { ... };

	my $self = shift;
	$self->init(@_);
	my $declarator = $self->declarator;
	my $is_trigger = $declarator eq 'trigger';

	$self->skip_declarator;
	$self->skipspace;

	my $line = $self->get_linestr;
	my $pos = $self->offset;
	my $insert = "";
	my $name;
	if (substr($line, $pos, 1) eq "[") {
		my $length = Devel::Declare::toke_scan_str($pos);
		$self->inc_offset($length);
	}
	else {
		$name = $self->strip_name;
		$insert .= qq/"$name"/ if defined $name;
	}

	my $proto = $self->strip_proto;
	$proto //= '$new, $old' if $is_trigger;

	my $attrs = $self->strip_attrs;

	$insert .= ", method ";
	$insert .= "($proto) " if defined $proto;
	$insert .= "$attrs " if defined $attrs;

	my $inject = '';
	$inject = $self->scope_injector_call if defined $name;

	$self->inject_if_block($inject, $insert)
		or croak "Illegal $declarator definition:\n$line";

	$self->shadow( \&trigger );

	return;
}

our @_prefix = '';
sub class_or_role_parser {
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
	my $is_role = $declarator eq "role" ? 1 : 0;

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

	my $type = $is_role ? "role" : "class";
	my $insert = '';
	$insert .= ";{ package $package; { use Neverhood::Base ':$type';";
	$insert .= qq(BEGIN { Neverhood::Base::Declare::on_class_or_role_end("$package", $is_role) });
	substr($line, $start_pos, $pos - $start_pos) = $insert;
	$self->set_linestr($line);

	return;
}

sub on_class_or_role_end {
	my ($package, $is_role) = @_;
	on_scope_end {
		my $line = Devel::Declare::get_linestr;
		my $pos = Devel::Declare::get_linestr_offset;
		my $insert =  "no Neverhood::Base;";
		$insert .= "$package->meta->make_immutable;" if !$is_role;
		$insert .= 'BEGIN { pop @Neverhood::Base::Declare::_prefix }';
		$insert .= "0 }";
		substr($line, $pos, 0) = $insert;
		Devel::Declare::set_linestr $line;
	}
}

sub assert_parser {
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

	return;
}

1;
