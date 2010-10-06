package Games::Neverhood::Scene;
use 5.01;
use strict;
use warnings;

use Games::Neverhood::Holder;

our $Nursery1 = Games::Neverhood::Scene->new(
	folder => 'nursery_1',
	fps => 24,
	bounds => [ 151, 60, 500, 479 ],
	ground => 43,
	# cursors => sub {
		# return $CursorRight->flip if $_[0] < 100;
		# return $CursorRight if $_[0] > 540;
		# ...
	# },
	event_rects => {
		lever => [40, 300, 60, 80],
		door => [520, 220, 60, 220],
		window => [0, 0, 0, 0],
		button => [0, 0, 0, 0],
	},
	moves => sub {
		my ($self, $click, $klaymen) = @_;
		if($klaymen->sprite_name eq 'snore' and @$click) {
			shift_click();
			$klaymen->sprite_name = 'wake';
		}
		elsif($self->rect('lever')) {
			$self->move_to(151, 'pull_lever');
		}
		elsif($self->rect('door')) {
			if($self->sprite('door')->hide) {
				$self->move_to(700);
			}
			else {
				$self->move_to(500, 'think');
			}
		}
		else {
			'_';
		}
		# lever 151
		# left window 300
		# right window 391
		# button 370
	},
	events => {
		pull_lever => sub { $_[2]->sprite_name = 'pull_lever' },
		think      => sub { $_[2]->sprite_name = 'idle_think' },
	},
	
	holders => [
		{ background => {} },
		
		{ lever => {
			frames => 7,
			sequences => [
				[ 0 ],
				[ 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 4, 4, 3, 3, 2, 2, 1, 1 ],
			],
			events => {
				0 => sub {
					if($_[1]->{klaymen}->sprite_name eq 'pull_lever' and int $_[1]->{klaymen}->sprite->frame == 26) {
						$_[0]->sequence_num = 1;
						$_[0]->frame = 0 + $_[1]->{klaymen}->sprite->frame_remainder;
					}
				},
				1 => sub { $_[0]->sequence_num = 0 if $_[1]->{end}; }
			}
		}, pos => [ 65, 313 ]},
		
		{ window => {
			frames => 4,
			sequences => [
				[ 0 ],
				[ 1, 2, 3 ],
			],
		}, pos => [ 317, 211 ]},
		
		{ button => {}, pos => [ 466, 339 ], hide => 1 },
		
		{ door => {
			frames => 7,
			sequences => [
				[ 0 ],
				[ 1, 1, 2, 2, 3, 3 ],
				[ 4 ],
				[ 2 ],
				[ 5, 5, 6, 6 ],
			],
		}, pos => [ 493, 212 ]},
		
		$Games::Neverhood::Klaymen,
		
		{ hammer => {
			frames => 14,
			sequences => [
				[ 0 ],
				[ 1, 1, 2, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10, 11, 11, 12, 12, 13, 13 ],
			],
		}, pos => [ 375, 30 ]},
		
		{ foreground => {}, pos => [ 574, 246 ] },
	],	
);

our $Nursery1OutWindow = Games::Neverhood::Scene->new(
	folder => 'nursery_1',
	fps => 24,
	bounds => [ 151, 60, 500, 479 ],
	ground => 43,
	# cursor => sub {
		# return $CursorRight->flip if $_[0] < 100;
		# return $CursorRight if $_[0] > 540;
		# ...
	# },
);

1;
