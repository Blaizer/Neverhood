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
use Scalar::Util ();
use Neverhood::Base::Object::Type;

Mouse::Exporter->setup_import_methods(
	as_is => [
		qw( ro rw rw_ re ),
	],
	also => [ 'Neverhood::Base::Util' ],
);

# attribute declaration customised
sub _has {
	my $caller = caller;
	my $meta = $caller->meta;
	my $caller_options = shift; # options from ro/rw/rw_
	my $name = shift;
	my @names = ref $name ? @$name : $name;
	if (@_ & 1) {
		# if there's odd number of elements it means the first argument is a default
		unshift @_, "default";
	}

	$name = join "__", map { s/^\+?\_?//; $_ } map $_, @names;
	my %options = (@$caller_options, @_);

	my $reader   = $options{reader};
	my $writer   = $options{writer};
	my $init_arg = $options{init_arg};

	my $predicate = $options{predicate};
	my $clearer   = $options{clearer};

	$options{builder} = "_build_$name" if $options{builder} and !ref $options{builder} and $options{builder} eq 1;
	$options{trigger} = \&{"$caller\::_trigger_$name"} if $options{trigger} and !ref $options{trigger};

	my @isa;
	for my $option (qw/constraint check coerce/) {
		if (exists $options{$option}) {
			my $value = delete $options{$option};
			$value = \&{"$caller\::_$option\_$name"} if $value and !ref $value;
			push @isa, $option => $value;
		}
	}
	$options{isa} = Neverhood::Base::Object::Type->new(name => $name, @isa) if @isa;
	$options{coerce} = 1 if $options{isa} and $options{isa}->has_coercion;

	for my $orig_name (@names) {
		(my $name = $orig_name) =~ s/^\+?(_?)//;
		$options{reader}   = $1.$name if $reader;
		$options{writer}   = $1."set_$name" if $writer;
		$options{init_arg} = $name if $init_arg;

		$options{predicate} = $1."has_$name" if $predicate;
		$options{clearer} = $1."clear_$name" if $clearer;

		$meta->add_attribute( $orig_name, %options );
	}

	return;
}

# redefine the default for attributes without creating new accessors
sub re {
	my $caller = caller;
	my $meta = caller->meta;
	my $name = shift;

	unshift @_, "default" if @_ & 1;
	my %options = @_;

	for my $name (ref $name ? @$name : $name) {
		my $attr = $meta->find_attribute_by_name($name)
			or $meta->throw_error("Couldn't find attribute '$name' to redefine in ".$meta->name);

		exists $options{default} || exists $options{builder} and !$attr->is_lazy
			or $meta->throw_error("Can't redefine default/builder for attribute '$name' because it is lazy");

		$attr = bless { %$attr, %options }, ref $attr;
		delete $attr->{builder} if exists $options{builder} && !defined $options{builder};

		# register the attribute to the metaclass
		Scalar::Util::weaken( $attr->{associated_class} = $meta );
		$meta->{attributes}{$name} = $attr;
		$meta->_invalidate_metaclass_cache();
	}

	return;
}

sub ro  { unshift @_, [ reader => 1, required => 1, init_arg => 1 ]; goto &_has }
sub rw  { unshift @_, [ reader => 1, writer => 1, init_arg => 1   ]; goto &_has }
sub rw_ { unshift @_, [ reader => 1, writer => 1, init_arg => 0   ]; goto &_has }

1;
