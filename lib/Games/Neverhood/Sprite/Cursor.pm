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

sub sequence {
	my ($self) = @_;
	my $type = $_->cursor_type;
	my ($x, $y) = @{$self->pos};

	my $return;
	if($type eq 'click') {
		$return = 'click';
	}
	elsif($type eq 'out') {
		my $out = 20;
		$return =
			$x <  $out       ? 'left'  :
			$x >= 640 - $out ? 'right' : 'click';
	}
	else {
		my $middle;

		my $up_down = 50;
		if($type =~ /up/) {
			$middle = 1;
			$return = 'up';
		}
		if($type =~ /forward/) {
			$middle = 1;
			$return = 'forward' if !$middle or $y >= $up_down;
		}
		if($type =~ /down/) {
			$middle = 1;
			$return = 'down' if !$middle or $y >= 480 - $up_down;
		}
		if($type =~ /sides/) {
			if($middle) {
				my $sides = 70;
				if   ($x <  $sides      ) { $return = 'left'  }
				elsif($x >= 640 - $sides) { $return = 'right' }
			}
			else {
				$return = $x < 640/2 ? 'left' : 'right';
			}
		}
	}
	wantarray ? ($return, $self->frame) : $return;
}

1;
