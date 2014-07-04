=head1 NAME

Neverhood::Base::Util - Common utility functions to export everywhere

=cut

use 5.01;
use strict;
use warnings;

package Neverhood::Base::Util;

use mro; # enable next::method and friends globally
use Mouse ();
use Mouse::Role ();
use Mouse::Exporter ();
use Carp qw/ confess /;
use File::Spec::Functions qw/ catfile catdir /;
use Scalar::Util qw/ weaken blessed /;
use List::Util qw/ max min /;

Mouse::Exporter->setup_import_methods(
	# only use names here because coderefs can't be unimported
	as_is => [
		qw( confess debug error debug_stack ),
		qw( catfile catdir ),
		qw( maybe ),
		qw( max min weaken blessed ),
	],
);

BEGIN {
	# This single dynamic library contains the rest of the booting functions we need to call
	require DynaLoader;
	@Neverhood::XS::ISA = 'DynaLoader';
	Neverhood::XS->bootstrap;

	# Now we need to call all of those booting functions from that library.
	# Couldn't get this code to work reliably in XS, but this Perl solution works.
	# This code follows stuff that DynaLoader.pm does when bootstrapping

	# get the libref and file of Neverhood::XS (the last module bootstrapped)
	my $libref = $DynaLoader::dl_librefs[-1];
	my $file = $DynaLoader::dl_shared_objects[-1];

	sub boot (*) {
		my ($module) = @_;

		# get the boot symbol for the module from the library loaded above
		my $boot_name = "boot_$module";
		$boot_name =~ s/\W/_/g;
		@DynaLoader::dl_require_symbols = $boot_name;

		my $boot_symbol_ref = DynaLoader::dl_find_symbol($libref, $boot_name);
		if (!$boot_symbol_ref) {
			# dying during begin looks ugly, so let's do this
			eval { die "Can't find '$boot_name' symbol in $file" };
			exit print STDERR $@;
		}

		# install the symbol and call it
		my $bootstrap = DynaLoader::dl_install_xsub("$module\::bootstrap", $boot_symbol_ref, $file);
		$module->$bootstrap;
	}

	# only export this sub to main
	*::boot = \&boot;
}

sub debug {
	return $;->debug if !@_;
	return if !$;->debug;

	my ($sub, $filename, $line) = _get_sub_filename_line();

	say STDERR sprintf(shift, @_);
	say STDERR sprintf "----- at %s(), %s line %d:", $sub, $filename, $line;
	return;
}
sub debug_stack {
	return $;->debug if !@_;
	return if !$;->debug;
	Carp::cluck(sprintf shift, @_);
	say STDERR sprintf "-----";
}
sub error {
	Carp::confess(sprintf shift, @_);
	say STDERR sprintf "-----";
}
sub _get_sub_filename_line {
	my ($package, $filename, $line) = (caller 1);
	my ($sub)                       = (caller 2)[3];

	# removes the package name at the start of the sub name
	$sub =~ s/^\Q$package\::\E//;

	# might replace the full lib name from the filename with lib
	my $i = -1;
	1 until ++$i > $#INC or $filename =~ s/^\Q$INC[$i]\E/lib/;

	return($sub, $filename, $line);
}

# returns what it was given, but returns an empty list if the value is undefined
sub maybe {
	if    (@_ == 2) { return @_ if defined $_[1] }
	elsif (@_ == 1) { return @_ if defined $_[0] }
	else { error("maybe() needs 1 or 2 arguments but was called with %d", scalar @_) }
	return;
}

# Always call Mouse::Object::BUILDARGS once and at the end of the chain
sub next::buildargs {
	my $method = mro::_nextcan($_[0], 0);
	goto &$method if defined $method;
	goto &Mouse::Object::BUILDARGS;
}

1;
