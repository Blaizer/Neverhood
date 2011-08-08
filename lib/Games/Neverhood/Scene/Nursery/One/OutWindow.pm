package Games::Neverhood::Scene::Nursery::One::OutWindow;
use 5.01;
use strict;
no strict 'refs';
use warnings;

use parent Games::Neverhood::Scene;

sub import {
	${+__PACKAGE__} = __PACKAGE__->SUPER::new(
		all_folder => ['nursery', 'one'],
		cursors => \&cursors_out,
		sprites => [
			out_window => {
				out => sub { $Scene->set('Nursery::One') }
			},
			$Klaymen,
		],
		setup => sub {
			$Klaymen->hide(1);
		},
		setdown => sub {
			$Klaymen
				->set(undef, 0, 2)
				->hide(0)
			;
		},
	);
}

1;
