package Neverhood::Base::Object::Class;

use 5.01;
my @_exports; BEGIN { @_exports = qw/ before after around / }
use Mouse @_exports;
use Mouse::Exporter ();

Mouse::Exporter->setup_import_methods(
	as_is => [ @_exports, qw/ extends with / ],
	also => [ 'Neverhood::Base::Object' ],
);

sub extends (*@) {
	goto \&Mouse::extends;
}
sub with (*@) {
	goto \&Mouse::with;
}

BEGIN {
	*init_meta = \&Mouse::init_meta;
}

1;
