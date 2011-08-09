package Games::Neverhood::GameMode;
use 5.01;
use strict;
use warnings;

use File::Spec ();

use Games::Neverhood qw/$Game $App/;

use overload
	'""'   => sub { ref($_[0]) =~ /^Games::Neverhood::(.*)/ and return $1; $_[0] },
	'0+'   => sub { no overloading; $_[0] },
	'fallback' => 1,
;

our $Set;

sub set {
	my ($unset) = @_;
	if(defined $_[1]) {
		$Set = $_[1];
		return $unset;
	}
	return $unset unless defined $Set;

	my $set_name = "Games::Neverhood::" . $Set;
	undef $Set;

	eval "use $set_name" or die $@;
	no strict 'refs';
	my $set = ${$set_name};

	$unset->setdown->($unset, $set);
	$set->setup->($set, $unset);

	$Game = $set;
	undef ${ref $unset};
	undef $unset;

	$App->dt(1 / $set->fps);
	$Cursor->sprite($set->cursor_sprite);
	$set;
}

1;
