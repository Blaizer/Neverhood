use 5.01;
use strict;
use warnings;
package Games::Neverhood::Scene::Nursery::One;

use parent 'Games::Neverhood::Scene';

sub on_new {
	my ($self) = @_;
	$self->klaymen
		->pos([200, 43])
		->sequence('snore')
	;
	if($self->GG->{nursery_1_window_open}) { $self->sprites->{window}->hide(1) }
	$self;
}
sub on_destroy {
	my ($self) = @_;
	$self->GG->{nursery_1_window_open} = 1 if $self->sprites->{window}->hide;
}

sub sprites_list {[
	'door_cover',
	$_[0]->klaymen,
	'hammer_cover',
	'hammer',
	'door',
	'button',
	'window_cover',
	'window',
	'lever_cover',
	'lever',
	'background',
]}

sub on_click {
	my ($self) = @_;
	if($self->klaymen->sequence eq 'snore') {
		$self->klaymen->sequence('wake');
	}
	elsif($self->sprites->{door}->in_rect and $_[0]->klaymen->sprite ne 'think') {
		if($self->sprites->{door}->hide) {
			$self->klaymen->move_to(to => 700);
		}
		else {
			$self->klaymen->move_to(left => 500, set => ['idle_think']);
		}
	}
	elsif($self->sprites->{button}->in_rect) {
		$self->klaymen->move_to(left => 370, set => ['push_button_back']);
	}
	elsif($self->sprites->{window}->in_rect and $self->sprites->{window}->hide) {
		$self->klaymen->move_to(left => 300, right => [391, 370], set => ['turn_to_back']);
	}
	elsif($self->sprites->{lever}->in_rect) {
		$self->klaymen->move_to(right => 150, set => ['pull_lever']);
	}
	elsif($self->in_rect) {
		$self->klaymen->move_to(to => $self->cursor->clicked->[0]);
	}
	else {
		return;
	}
	$self->clicked(undef);
}
sub on_space {
	$_[0]->sprites->{button}->hide(!$_[0]->sprites->{button}->hide);
}

package Games::Neverhood::Scene::Nursery::One::door_cover;
	use constant {
		file => 505,
		pos => [ 640-68, 480-280 ],
		alpha => 0,
	};
	sub palette { $;->sprites->{background} }
	sub on_show {
		$;->sprites->{background}->show_at([581, 200], [581, 200, 59, 262]);
	}

package Games::Neverhood::Scene::Nursery::One::hammer_cover;
	use constant {
		file => 501,
		pos => [541, 188],
		alpha => 0,
	};
	sub palette { $;->sprites->{background} }
	
package Games::Neverhood::Scene::Nursery::One::hammer;
	use constant {
		file => 89,
		dir => 's',
		pos => [499, 29],
		alpha => 0,
		vars => {
			sequence => 'idle',
		},
		sequences => {
			idle => { frames => [14] },
			swing => { frames => [1,1,2,3,4,4,5,5,6,6,7,7,8,8,9,9,10,10,11,11,12,12,13,13], next_sequence => 'idle' },
		},
	};
	sub on_move {
		if([$;->klaymen->sequence] ~~ ['pull_lever', 42]) {
			$_[0]->sequence('swing');
		}
	}

package Games::Neverhood::Scene::Nursery::One::door;
	use constant {
		file => 63,
		dir => 's',
		pos => [535, 215],
		rect => [520, 200, 90, 250],
		alpha => 0,
		vars => {
			sequence => 'idle_1',
		},
		sequences => {
			idle_1 => { frames => [0] },
			bash_1 => { frames => [1,1,2,2,3,3], next_sequence => 'idle_2' },
			idle_2 => { frames => [4] },
			bash_2 => { frames => [1,1,2,2,3,3], next_sequence => 'idle_3' },
			idle_3 => { frames => [1] },
			bash_3 => { frames => [5,5,6,6] },
		},
	};
	sub on_move {
		if([$;->klaymen->sequence] ~~ ['pull_lever', 47]) {
			$_[0]->sequence =~ /(\d)/;
			# go from sequence idle_n to bash_n
			$_[0]->sequence("bash_$1");
		}
		elsif([$_[0]->sequence] ~~ ['bash_3', 'end']) {
			$_[0]->hide(1);
		}
	}

package Games::Neverhood::Scene::Nursery::One::button;
	use constant {
		file => 503,
		pos => [462, 335],
		rect => [455, 325, 40, 40],
		alpha => 0,
		vars => {
			hide => 1,
		},
	};
	sub palette { $;->sprites->{background} }
	sub on_move {
		if($;->klaymen->sequence eq 'push_button_back') {
			if($;->klaymen->frame == 51) {
				$_[0]->hide(0);
			}
			elsif($;->klaymen->frame == 58) {
				$_[0]->hide(1);
			}
		}
	}

package Games::Neverhood::Scene::Nursery::One::window_cover;
	use constant {
		file => 504,
		pos => [317, 211],
		alpha => 0,
	};
	sub palette { $;->sprites->{background} }
	sub on_show {
		my $background = $;->sprites->{background};
		$background->show_at([317, 338], [317, 338, 66, 2]);
		$background->show_at([381, 211], [381, 211, 2, 127]);
	}
	
package Games::Neverhood::Scene::Nursery::One::window;
	use constant {
		file => 261,
		dir => 's',
		pos => [317, 211],
		rect => [315, 200, 70, 140],
		alpha => 0,
		vars => {
			sequence => 'idle',
		},
		sequences => {
			idle => { frames => [0] },
			open => { frames => [1,2,3] },
		},
	};
	sub on_move {
		if($_[0]->sequence eq 'idle' and [$;->klaymen->sequence] ~~ ['push_button_back', 53]) {
			$_[0]->sequence('open');
		}
		elsif($_[0]->hide and [$;->klaymen->sequence] ~~ ['look_back', 'end']) {
			$;->set('Scene::Nursery::One::OutWindow');
		}
	}

package Games::Neverhood::Scene::Nursery::One::lever_cover;
	use constant {
		file => 502,
		pos => [42, 330],
		alpha => 0,
	};
	sub palette { $;->sprites->{background} }
	
package Games::Neverhood::Scene::Nursery::One::lever;
	use constant {
		file => 37,
		dir => 's',
		pos => [100, 313],
		rect => [40, 300, 70, 100],
		mirror => 1,
		alpha => 0,
		vars => {
			sequence => 'idle',
		},
		sequences => {
			idle => { frames => [0] },
			pull => { frames => [1,1,2,2,3,3,4,4,5,5,6,6,4,4,3,3,2,2,1,1], next_sequence => 'idle' },
		},
	};
	sub on_move {
		if($_[0]->sequence eq 'idle' and [$;->klaymen->sequence] ~~ ['pull_lever', 26]) {
			$_[0]->sequence('pull');
		}
	}

package Games::Neverhood::Scene::Nursery::One::background;
	use constant {
		file => 496,
	};

1;
