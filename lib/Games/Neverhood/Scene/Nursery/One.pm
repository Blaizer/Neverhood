package Games::Neverhood::Scene::Nursery::One;
use 5.01;
use strict;
use warnings;

use Games::Neverhood::Scene '$Klaymen';
use Games::Neverhood '$Game', '%GG';
our ($Klaymen, $Game, %GG);
our @ISA = 'Games::Neverhood::Scene';

sub import {
	$Game = __PACKAGE__->SUPER::new(
		all_folder => ['nursery', 'one'],
		move_bounds => [151, 60, 500, 479],
		on_set => sub {
			if($GG{nursery_1_window_open} == 1) { $Game->sprites->{window}->hide }
			$Klaymen
				->pos([200, 43])
				->set('snore')
			;
		},
		on_unset => sub {
			$GG{nursery_1_window_open} = 1 if $Game->sprites->{window}->hide;
		}
		sprites => [
			background => {
				on_click => sub {
					if($Klaymen->get('snore')) { $Klaymen->set('wake') }
				},
			},

			lever => {
				pos => [65, 313],
				sequences => [
					[ 0 ],
					[ 1,1,2,2,3,3,4,4,5,5,6,6,4,4,3,3,2,2,1,1 ],
				],
				on_click => sub {
					if($_[0]->rect(40, 300, 70, 100)) { $_[0]->move_to(right => 150, set => ['pull_lever']) }
				},
				actions => {
					0 => [
						sub { $Klaymen->get('pull_lever', 26) } => sub { $_[0]->set(undef, 0, 1) }
					],
					1 => [ end => sub { $_[0]->set(undef, 0, 0) } ],
				},
			},

			window => {
				pos => [317, 211],
				sequences => [
					[ 0 ],
					[ 1,2,3 ],
				],
				actions => {
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
				on_click => sub {
					if($_[0]->rect(315, 200, 70, 140) and $_[0]->hide) {
						$_[0]->move_to(left => 300, right => [391, 370], set => ['push_button_back', 0, 1])
					}
				},
			},

			button => {
				pos => [466, 339],
				hide => 1,
				on_click => sub {
					if($_[0]->rect(455, 325, 40, 40)) { $_[0]->move_to(left => 370, set => ['push_button_back']) }
				},
				actions => {
					0 => [
						sub { $Klaymen->get('push_button_back', 51) } =>
						sub { $_[0]->hide(0) },

						sub { $Klaymen->get('push_button_back', 58) } =>
						sub { $_[0]->hide(1) }
					],
				},
			},

			door => {
				pos => [493, 212],
				sequences => [
					[ 0 ],
					[ 1,1,2,2,3,3 ],
					[ 4 ],
					[ 1,1,2,2,3,3 ],
					[ 1 ],
					[ 5,5,6,6 ],
				],
				on_click => sub {
					if($_[0]->rect(520, 200, 90, 250) and $Klaymen->sprite ne 'think') {
						if($_[0]->hide) {
							$_[0]->move_to(to => 700);
						}
						else {
							$_[0]->move_to(left => 500, set => ['idle_think']);
						}
					}
				],
				actions => {
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
				pos => [375, 30],
				sequences => [
					[ 0 ],
					[ 1,1,2,3,4,4,5,5,6,6,7,7,8,8,9,9,10,10,11,11,12,12,13,13 ],
				],
				actions => {
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
