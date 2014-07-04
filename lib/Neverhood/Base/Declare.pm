use 5.01;
use strict;
use warnings;

package Neverhood::Base::Declare;
use Devel::Declare;

use Neverhood::Base::Declare::Sub;
use Neverhood::Base::Declare::Modifier;
use Neverhood::Base::Declare::Package;
use Neverhood::Base::Declare::Assert;

sub setup_declarators {
	my ($class, $caller) = @_;
	$caller //= caller;

	state $ctx = sub {
		my $class = shift;
		my $name = shift;
		my $ctx = $class->new(@_);
		return $name => { const => sub { $ctx->parser(@_) } };
	};

	state $contexts = {
		Neverhood::Base::Declare::Sub->$ctx( func    => ),
		Neverhood::Base::Declare::Sub->$ctx( method  => invocant => '$self' ),
		Neverhood::Base::Declare::Sub->$ctx( _around => invocant => '$self', pre_invocant => '$orig' ),

		Neverhood::Base::Declare::Modifier->$ctx( before => sub => 'method' ),
		Neverhood::Base::Declare::Modifier->$ctx( after  => sub => 'method' ),
		Neverhood::Base::Declare::Modifier->$ctx( around => sub => '_around' ),

		Neverhood::Base::Declare::Package->$ctx( class => ( make_immutable => 1 ) ),
		Neverhood::Base::Declare::Package->$ctx( role  => ( make_immutable => 0 ) ),

		Neverhood::Base::Declare::Assert->$ctx( assert => () ),
	};

	Devel::Declare->setup_for($caller, $contexts);
}

sub teardown_declarators {
	my ($class, $caller) = @_;
	$caller //= caller;
	Devel::Declare->teardown_for($caller);
}

1;
