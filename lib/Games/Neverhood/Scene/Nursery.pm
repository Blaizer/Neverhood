package Games::Neverhood::Scene;
use 5.01;
use strict;
use warnings;

use Games::Neverhood::Holder;

our $Nursery1 = Games::Neverhood::Scene->new(
	folder => 'nursery_1',
	fps => 24,
	bounds => [ 0, 639 ],
	klaymen_start => 200,
	# exits => [ [0, 0, $Nursery2], [...], ],
	ground => 43,
	# cursor => sub {
		# return $CursorRight->flip if $_[0] < 100;
		# return $CursorRight if $_[0] > 540;
		# ...
	# },
	
	holders => [
		{ background => {} },
		
		{ lever => {
			frames => 7,
			sequences => [
				[ 0 ],
				[ 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 4, 4, 3, 3, 2, 2, 1, 1 ],
			],
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

1;
