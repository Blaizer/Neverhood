package Games::Neverhood::Cursor;
use 5.01;
use strict;
use warnings;

use Games::Neverhood::Holder;

our $Default = Games::Neverhood::Holder->new(
	folder => 'cursor',
	default => {
		frames => 3,
		sequences => [[0, 0, 2, 2]],
	}
)->load;

our $Left = Games::Neverhood::Holder->new(
	folder => 'cursor',
	default => {
		frames => 3,
		sequences => [[0, 0, 2, 2]],
	}
)->load;

our $Forward = Games::Neverhood::Holder->new(
	folder => 'cursor',
	default => {
		frames => 3,
		sequences => [[0, 0, 2, 2]],
	}
)->load;

our $Right = Games::Neverhood::Holder->new(
	folder => 'cursor',
	default => {
		frames => 3,
		sequences => [[0, 0, 2, 2]],
	}
)->load;

1;
