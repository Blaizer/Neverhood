=head1 NAME

Neverhood::Base::Object - Some "has" sugar and whateverelse

=cut

use 5.01;
use strict;
use warnings;

package Neverhood::Base::Object;
use Mouse ();
use Mouse::Role ();
use Mouse::Exporter ();

Mouse::Exporter->setup_import_methods(
	as_is => [
		qw( re ro rw rw_ ),
		# qw( required ),
		# qw( weak_ref lazy_build ),
	],
	also => [ 'Neverhood::Base::Util' ],
);

# attribute declaration customised
sub _has {
	my $caller = caller;
	my $meta = $caller->meta;
	my $caller_options = shift; # options from ro/rw/rw_
	my $name = shift;

	if (@_ & 1) {
		# if there's odd number of elements it means the first argument is a default
		unshift @_, "default";
	}

	my %options = (@$caller_options, @_);
	my $reader   = $options{reader};
	my $writer   = $options{writer};
	my $builder  = $options{builder} && !ref $options{builder};
	my $trigger  = $options{trigger} && !ref $options{trigger};
	my $init_arg = $options{init_arg};
	my $re       = delete $options{re} ? "+" : "";

	for my $name (ref $name ? @$name : $name) {
		my $prefix = $name =~ s/^_// ? "_" : "";

		$options{reader}   = $prefix.$name if $reader;
		$options{writer}   = $prefix."set_$name" if $writer;
		$options{builder}  = "_build_$name" if $builder;
		$options{trigger}  = "_trigger_$name" if $trigger;
		$options{init_arg} = $name if $init_arg;

		$meta->add_attribute( $re.$name, %options );
	}

	return;
}

sub re  { unshift @_, [ re => 1                                     ]; goto &_has }
sub ro  { unshift @_, [ reader => 1, required => 1, init_arg => 1,  ]; goto &_has }
sub rw  { unshift @_, [ reader => 1, writer => 1, init_arg => 1     ]; goto &_has }
sub rw_ { unshift @_, [ reader => 1, writer => 1, init_arg => undef ]; goto &_has }

sub required   () { required => 1 }
sub weak_ref   () { weak_ref => 1 }
sub lazy_build () { lazy => 1, builder => 1 }

1;
