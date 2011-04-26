package Games::Neverhood::Scene::Nursery::One;
use 5.01;
use strict 'subs';
use warnings;

use Games::Neverhood::Scene;
our @ISA = 'Games::Neverhood::Scene';

use Data::Dumper;

sub import {
	${+__PACKAGE__} = __PACKAGE__->SUPER::new(
		all_folder => ['nursery', 'one'],
		bounds => [ 151, 60, 500, 479 ],
		on_set => sub {
			$Klaymen
				->pos([200, 43])
				->set('snore')
			;
		},
		sprites => [
			background => {
				click => [ '^snore$' => sub { $Klaymen->set('wake') } ]
			},

			lever => {
				pos => [65, 313],
				frames => 7,
				sequences => [
					[ 0 ],
					[ 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 4, 4, 3, 3, 2, 2, 1, 1 ],
				],
				click => [
					[40, 300, 70, 100] => sub { $_[0]->move_to(right => 150, set => ['pull_lever']) }
				],
				events => {
					0 => [
						sub { $Klaymen->get('pull_lever', 26) } =>
						sub { $_[0]->sequence(1) }
					],
					1 => [ end => sub { $_[0]->sequence(0) } ],
				},
			},

			window => {
				pos => [ 317, 211 ],
				frames => 4,
				sequences => [
					[ 0 ],
					[ 1, 2, 3 ],
				],
				events => {
					0 => [
						sub { $_[0]->sequence == 0 and $Klaymen->get('push_button_back', 53) } =>
						sub { $_[0]->sequence(1) }
					],
					1 => [
						end => sub { $_[0]->hide(1) },
						sub { $_[0]->hide == 1 and $Klaymen->get('push_button_back', 'end', 1) } =>
						sub { $Game->set('Scene::Nursery::One::OutWindow'); }
					],
				},
				click => [
					[315, 200, 70, 140, undef, sub{ $_[0]->hide }] =>
					sub { $_[0]->move_to(left => 300, right => [391, 370], set => ['push_button_back', 0, 1]) }
				],
			},

			button => {
				pos => [ 466, 339 ],
				hide => 1,
				click => [
					[455, 325, 40, 40] => sub { $_[0]->move_to(left => 370, set => ['push_button_back']) }
				],
				events => {
					0 => [
						sub { $Klaymen->get('push_button_back', 51) } =>
						sub { $_[0]->hide(0) },

						sub { $Klaymen->get('push_button_back', 58) } =>
						sub { $_[0]->hide(1) }
					],
				},
			},

			door => {
				pos => [ 493, 212 ],
				frames => 7,
				sequences => [
					[ 0 ],
					[ 1, 1, 2, 2, 3, 3 ],
					[ 4 ],
					[ 1, 1, 2, 2, 3, 3 ],
					[ 1 ],
					[ 5, 5, 6, 6 ],
				],
				click => [
					[520, 200, 90, 250, '^idle(?!_think$)'] => sub {
						if($_[0]->hide) {
							$_[0]->move_to(to => 700);
						}
						else {
							$_[0]->move_to(left => 500, set => ['idle_think']);
						}
					}
				],
				events => {
					0 => [
						sub { $Klaymen->get('pull_lever', 47) } =>
						sub { $_[0]->sequence(1) }
					],
					1 => [ end => sub { $_[0]->sequence(2) } ],
					2 => [
						sub { $Klaymen->get('pull_lever', 47) } =>
						sub { $_[0]->sequence(3) }
					],
					3 => [ end => sub { $_[0]->sequence(4) } ],
					4 => [
						sub { $Klaymen->get('pull_lever', 47) } =>
						sub { $_[0]->sequence(5) }
					],
					5 => [ end => sub { $_[0]->hide(1) } ],
				},
			},

			$Klaymen,

			hammer => {
				pos => [ 375, 30 ],
				frames => 14,
				sequences => [
					[ 0 ],
					[ 1, 1, 2, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10, 11, 11, 12, 12, 13, 13 ],
				],
				events => {
					0 => [
						sub { $Klaymen->get('pull_lever', 42) } =>
						sub { $_[0]->sequence(1) }
					],
					1 => [ end => sub { $_[0]->sequence(0) } ],
				},
			},

			foreground => { pos => [ 574, 246 ] },
		],
	);
}

1;
