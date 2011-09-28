use 5.01;
use strict;
use warnings;
package Games::Neverhood::Scene::Test;

use parent qw/Games::Neverhood::Scene/;

use constant {
	fps => 24,
	cursor_type => 'sides_down',
};
sub sprites_list {
	[
		'test',
		'background',
	];
}

package Games::Neverhood::Scene::Test::test;
our @ISA = qw/Games::Neverhood::Sprite/;

use constant {
	file => 142,
	dir => 's',
	sequence => 'blink',
	# alpha => 1,
	# mirror => 1,
	sequences => {
		blink => { frames => [0,1,2,3] },
	},
};

package Games::Neverhood::Scene::Test::background;
	our @ISA = qw/Games::Neverhood::Sprite/;
	use constant {
		file => 496,
	};

sub on_move {

}

1;