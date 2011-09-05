use 5.01;
use strict;
use warnings;
package Games::Neverhood::Sprite::Cursor;

use parent 'Games::Neverhood::Sprite';

${;no strict;__PACKAGE__} = __PACKAGE__->SUPER::new(
	all_folder => 'cursor',
	click => {
		sequences => [[0, 0, 1, 1]],
	},
	# left => {
		# sequences => [[0, 0, 1, 1]],
	# },
	# right => {
		# sequences => [[0, 0, 1, 1]],
	# },
	# forward => {
		# sequences => [[0, 0, 1, 1]],
	# },
	# up => {
		# sequences => [[0, 0, 1, 1]],
	# },
	# down => {
		# sequences => [[0, 0, 1, 1]],
	# },
);

1;
