use 5.01;
use strict;
use warnings;
package Games::Neverhood::Scene::Nursery::One;

use parent 'Games::Neverhood::Scene';

use constant {
	sprites_list => [
		'foreground',
		$_[0]->klaymen,
		'hammer',
		'door',
		'button'
		'window',
		'lever',
		'background',
	],
	move_klaymen_bounds => [151, 60, 500, 479],
};
sub new {
	my $self = $_[0]->SUPER::new;
	if($self->GG->{nursery_1_window_open}) { $self->sprites->{window}->hide }
	$self->klaymen
		->pos([200, 43])
		->set('snore')
	;
	$self;
}
sub DESTROY {
	my ($self) = @_;
	$self->GG->{nursery_1_window_open} = 1 if $self->sprites->{window}->hide;
}

package Games::Neverhood::Scene::Nursery::One::background;
	sub on_click {
		if($_->klaymen->sequence eq 'snore') { $_->klaymen->sequence('wake') }
		else { 'no' }
	}

package Games::Neverhood::Scene::Nursery::One::lever;
	sub new {
		$_[0]->SUPER::new(
			pos => [65, 313],
			sequence => 'idle',
		);
	}
	use constant {
		sequences => {
			idle => { frames => [0] },
			pull => { frames => [1,1,2,2,3,3,4,4,5,5,6,6,4,4,3,3,2,2,1,1], next_sequence => 'idle' },
		},
	};
	sub on_click {
		if($_[0]->in_rect(40, 300, 70, 100)) { $_[0]->move_klaymen_to(right => 150, set => ['pull_lever']) }
		else { 'no' }
	}
	sub on_move {
		if($_[0]->sequence eq 'idle' and $_->klaymen->sequence ~~ ['pull_lever', 26]) {
			$_[0]->sequence('pull');
		}
	}

package Games::Neverhood::Scene::Nursery::One::window;
	sub new {
		$_[0]->SUPER::new(
			pos => [317, 211],
			sequence => 'idle',
		);
	}
	use constant {
		sequences => {
			idle => { frames => [0] },
			open => { frames => [1,2,3] },
		},
	};
	sub on_move {
		if($_[0]->sequence eq 'idle' and $_->klaymen->sequence ~~ ['push_button_back', 53]) {
			$_[0]->sequence('open');
		}
		elsif($_[0]->hide and $_->klaymen->sequence ~~ ['look_back', 'end']) {
			$_->set('Scene::Nursery::One::OutWindow');
		}
	}
	sub on_click {
		if($_[0]->in_rect(315, 200, 70, 140) and $_[0]->hide) {
			$_[0]->move_klaymen_to(left => 300, right => [391, 370], set => ['push_button_back'])
		}
		else { 'no' }
	}


package Games::Neverhood::Scene::Nursery::One::button;
	sub new {
		$_[0]->SUPER::new(
			pos => [466, 339],
			hide => 1,
		);
	}
	sub on_click {
		if($_[0]->in_rect(455, 325, 40, 40)) { $_[0]->move_klaymen_to(left => 370, set => ['push_button_back']) }
		else { 'no' }
	}
	sub on_move {
		if($_->klaymen->sequence eq 'push_button_back') {
			if($_->klaymen->frame == 51) {
				$_[0]->hide(0);
			}
			elsif($_->klaymen->frame == 58) {
				$_[0]->hide(1);
			}
		}
	}


package Games::Neverhood::Scene::Nursery::One::door;
	sub new {
		$_[0]->SUPER::new(
			pos => [493, 212],
			sequence => 'idle_1';
		);
	}
	use constant {
		sequences => {
			idle_1 => { frames => [0] }
			bash_1 => { frames => [1,1,2,2,3,3], next_sequence => 'idle_2' },
			idle_2 => { frames => [4] },
			bash_2 => { frames => [1,1,2,2,3,3], next_sequence => 'idle_3' },
			idle_3 => { frames => [1] },
			bash_3 => { frames => [5,5,6,6] },
		},
	};
	sub on_click {
		if($_[0]->in_rect(520, 200, 90, 250) and $_->klaymen->sprite ne 'think') {
			if($_[0]->hide) {
				$_[0]->move_klaymen_to(to => 700);
			}
			else {
				$_[0]->move_klaymen_to(left => 500, set => ['idle_think']);
			}
		}
		else { 'no' }
	}
	sub on_move {
		if($_->klaymen->sequence ~~ ['pull_lever', 47]) {
			$_[0]->sequence =~ /(\d)/;
			# go from idle_(\d) to bash_(\d)
			$_[0]->sequence("bash_$1");
		}
		elsif($_[0]->sequence ~~ ['bash_3', 'end']) {
			$_[0]->hide(1);
		}
	}


package Games::Neverhood::Scene::Nursery::One::hammer;
	sub new {
		$_[0]->SUPER::new(
			pos => [375, 30],
		);
	}
	use constant {
		sequences => {
			idle => { frames => [0] }
			swing => { frames => [1,1,2,3,4,4,5,5,6,6,7,7,8,8,9,9,10,10,11,11,12,12,13,13], next_sequence => 'idle' }
		},
	};
	sub on_move {
		if($_->klaymen->sequence ~~ ['pull_lever', 42]) {
			$_[0]->sequence('swing');
		}
	}

package Games::Neverhood::Scene::Nursery::One::foreground;
	sub new {
		$_[0]->SUPER::new(
			pos => [ 574, 246 ]
		);
	}

1;
