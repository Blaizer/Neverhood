package Games::Neverhood::Scene::Nursery::One;
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
		all_folder => ['nursery', 'one'],
		bounds => [ 151, 60, 500, 479 ],
		setup => sub {
			$_[1]->{klaymen}->pos([200, 43])
			->sprite('snore');
		},
		sprites => [
			{ background => {
				click => [ '^snore$' => sub { $_[1]->{klaymen}->set('wake') } ]
			} },

			{ lever => {
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
						sub { $_[1]->{klaymen}->get('pull_lever', 26) } =>
						sub { $_[0]->sequence(1) }
					],
					1 => [ end => sub { $_[0]->sequence(0) } ],
				},
			}, pos => [ 65, 313 ]},

			{ window => {
				frames => 4,
				sequences => [
					[ 0 ],
					[ 1, 2, 3 ],
				],
				events => {
					0 => [
						sub { $_[0]->sequence == 0 and $_[1]->{klaymen}->get('push_button_back', 53) } =>
						sub { $_[0]->sequence(1) }
					],
					1 => [
						end => sub { $_[0]->hide(1) },
						sub { $_[0]->hide == 1 and $_[1]->{klaymen}->get('push_button_back', 'end', 1) } =>
						sub { __PACKAGE__->set('Nursery::One', 'OutWindow'); }
					],
				},
				click => [
					[315, 200, 70, 140, undef, sub{ $_[0]->hide }] =>
					sub { $_[0]->move_to(left => 300, right => [391, 370], set => ['push_button_back', 0, 1]) }
				]
			}, pos => [ 317, 211 ]},

			{ button => {
				click => [
					[455, 325, 40, 40] => sub { $_[0]->move_to(left => 370, set => ['push_button_back']) }
				],
				events => {
					0 => [
						sub { $_[1]->{klaymen}->get('push_button_back', 51) } =>
						sub { $_[0]->hide(0) },

						sub { $_[1]->{klaymen}->get('push_button_back', 58) } =>
						sub { $_[0]->hide(1); }
					],
				}
			}, pos => [ 466, 339 ], hide => 1 },

			{ door => {
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
					[520, 200, 90, 250, '^idle'] => sub {
						if($_[0]->hide) {
							$_[0]->move_to(to => 700);
						}
						elsif($_[1]->{klaymen}->sprite eq 'idle_think') {
							return 'not_yet';
						}
						else {
							$_[0]->move_to(left => 500, set => ['idle_think']);
						}
					}
				],
				events => {
					0 => [
						sub { $_[1]->{klaymen}->get('pull_lever', 47) } =>
						sub { $_[0]->sequence(1) }
					],
					1 => [ end => sub { $_[0]->sequence(2) } ],
					2 => [
						sub { $_[1]->{klaymen}->get('pull_lever', 47) } =>
						sub { $_[0]->sequence(3) }
					],
					3 => [ end => sub { $_[0]->sequence(4) } ],
					4 => [
						sub { $_[1]->{klaymen}->get('pull_lever', 47) } =>
						sub { $_[0]->sequence(5) }
					],
					5 => [ end => sub { $_[0]->hide(1) } ],
				}
			}, pos => [ 493, 212 ]},

			$Games::Neverhood::Klaymen,

			{ hammer => {
				frames => 14,
				sequences => [
					[ 0 ],
					[ 1, 1, 2, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10, 11, 11, 12, 12, 13, 13 ],
				],
				events => {
					0 => [
						sub { $_[1]->{klaymen}->get('pull_lever', 42) } =>
						sub { $_[0]->sequence(1) }
					],
					1 => [ end => sub { $_[0]->sequence(0) } ],
				}
			}, pos => [ 375, 30 ]},

			{ foreground => {}, pos => [ 574, 246 ] },
		],
		);
	}
	elsif($_[1] eq 'OutWindow') {
		package Games::Neverhood::Scene::Nursery::OneOutWindow;
		our @ISA = 'Games::Neverhood::Scene';
		${+__PACKAGE__} = __PACKAGE__->SUPER::new(
		all_folder => ['nursery', 'one'],
		cursors => \&Games::Neverhood::Scene::cursors_out,
		sprites => [
			{ out_window => {
				out => sub { __PACKAGE__->set('Nursery::One') }
			} },
			$Games::Neverhood::Klaymen,
		],
		setup => sub {
			$_[1]->{klaymen}->hide(1);
		},
		setdown => sub {
			$_[1]->{klaymen}->set(undef, 0, 2)
			->hide(0);
		},
		);
	}
}

1;
