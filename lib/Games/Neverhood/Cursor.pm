package Games::Neverhood::Cursor;
use 5.01;
use strict;
use warnings;
use parent 'Games::Neverhood::Sprite';

$Games::Neverhood::Cursor = Games::Neverhood::Cursor->SUPER::new(
	all_folder => 'cursor',
	click => {
		frames => 3,
		sequences => [0, 0, 2, 2],
	},
	left => {
		frames => 3,
		sequences => [0, 0, 2, 2],
	},
	right => {
		frames => 3,
		sequences => [0, 0, 2, 2],
	},
	forward => {
		frames => 3,
		sequences => [0, 0, 2, 2],
	},
)->load;

sub clicked {
	if(@_ > 1) { $_[0]->{clicked} = $_[1]; return $_[0]; }
	$_[0]->{clicked};
}

1;
