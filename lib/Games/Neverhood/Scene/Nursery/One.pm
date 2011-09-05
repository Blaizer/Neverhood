package Games::Neverhood::Scene::Nursery::One;
use 5.01;
use strict;
use warnings;

use parent 'Games::Neverhood::Scene';

use constant {
	all_folder => ['nursery', 'one'],
	sprites_list => [
		'background',
		'lever',
		'window',
		'button'
		'door',
		'hammer',
		$_[0]->klaymen,
		'foreground',
	],
	move_bounds => [151, 60, 500, 479],
};
sub on_set {
	my ($self) = @_;
	if($self->GG->{nursery_1_window_open}) { $self->sprites->{window}->hide }
	$self->klaymen
		->pos([200, 43])
		->set('snore')
	;
}
sub on_unset {
	my ($self) = @_;
	$self->GG->{nursery_1_window_open} = 1 if $self->sprites->{window}->hide;
}

package Games::Neverhood::Scene::Nursery::One::background;
	sub on_click {
		if($Klaymen->get('snore')) { $Klaymen->set('wake') }
	},

package Games::Neverhood::Scene::Nursery::One::lever;
	sub new {
		$_[0]->SUPER::new(
			pos => [65, 313],
		);
	}
	use constant {
		sequences => [
			[ 0 ],
			[ 1,1,2,2,3,3,4,4,5,5,6,6,4,4,3,3,2,2,1,1 ],
		],
	}
	sub on_click {
		if($_[0]->rect(40, 300, 70, 100)) { $_[0]->move_to(right => 150, set => ['pull_lever']) }
	}
	sub move {
		0 => [
			sub { $Klaymen->get('pull_lever', 26) } => sub { $_[0]->set(undef, 0, 1) }
		],
		1 => [ end => sub { $_[0]->set(undef, 0, 0) } ],
	},

package Games::Neverhood::Scene::Nursery::One::window;
	sub new {
		$_[0]
				pos => [317, 211],
	}
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
						sub { Games::Neverhood->set('Scene::Nursery::One::OutWindow'); }
					],
				},
				on_click => sub {
					if($_[0]->rect(315, 200, 70, 140) and $_[0]->hide) {
						$_[0]->move_to(left => 300, right => [391, 370], set => ['push_button_back', 0, 1])
					}
				},


package Games::Neverhood::Scene::Nursery::One::button;
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


package Games::Neverhood::Scene::Nursery::One::door;
				pos => [493, 212],
				sequence => 'idle_1';
				sequences => {
					idle_1 => [ 0 ],
					bash_1 => [ 1,1,2,2,3,3 ],
					idle_2 => [ 4 ],
					bash_2 => [ 1,1,2,2,3,3 ],
					idle_3 => [ 1 ],
					bash_3 => [ 5,5,6,6 ],
				},
				on_click => sub {
					if($_[0]->rect(520, 200, 90, 250) and $Klaymen->sprite ne 'think') {
						if($_[0]->hide) {
							$_[0]->move_to(to => 700);
						}
						else {
							$_[0]->move_to(left => 500, set => ['idle_think']);
						}
					}
				},
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


package Games::Neverhood::Scene::Nursery::One::hammer;
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


package Games::Neverhood::Scene::Nursery::One::foreground;
pos => [ 574, 246 ]

1;
