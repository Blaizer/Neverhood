package Games::Neverhood::Scene::;
use 5.01;
use strict;
no strict 'refs';
use warnings;

use Games::Neverhood::Scene;
use Data::Dumper;

sub import {
	if($_[1] eq '') {
		our @ISA = 'Games::Neverhood::Scene';
		${+__PACKAGE__} = __PACKAGE__->SUPER::new(
		all_folder => [],
		bounds => [],
		cursors => ,
		setup => sub {
		},
		setdown => sub {
		},
		sprites => [
		],
		);
	}
}

1;
