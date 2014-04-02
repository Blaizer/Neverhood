package Neverhood::Base::Object::Role;

use 5.01;
my @_exports; BEGIN { @_exports = qw/ before after around / }
use Mouse::Role @_exports;
use Mouse::Exporter ();
use Symbol ();

Mouse::Exporter->setup_import_methods(
	as_is => [ @_exports, qw/ requires with / ],
	also => [ 'Neverhood::Base::Object' ],
);

sub with (*@) {
	goto \&Mouse::Role::with;
}

sub requires {
	return;
}

BEGIN {
	*init_meta = \&Mouse::Role::init_meta;
}

1;
