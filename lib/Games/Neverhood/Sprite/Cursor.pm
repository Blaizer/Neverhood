use 5.01;
use strict;
use warnings;
package Games::Neverhood::Sprite::Cursor;

use parent 'Games::Neverhood::Sprite';

use constant {
	sequences => {
		click => {
			frames => [0,0,1,1,2,2],
			offsets => [],
			clips => []
		},
		left => {
			frames => [0,0,1,1,2,2],
			offsets => [],
			clips => []
		},
		right => {
			frames => [0,0,1,1,2,2],
			offsets => [],
			clips => []
		},
		forward => {
			frames => [0,0,1,1,2,2],
			offsets => [],
			clips => []
		},
		up => {
			frames => [0,0,1,1,2,2],
			offsets => [],
			clips => []
		},
		down => {
			frames => [0,0,1,1,2,2],
			offsets => [],
			clips => []
		},
	},
};

1;
