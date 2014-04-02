use 5.01;
use strict;
use warnings;
package Neverhood::Sprite::Cursor;
use Carp;
use parent 'Neverhood::Sprite';

use constant {
	name => 'cursor',
	file => 38,
	dir => 'c',
	this_frames => 6,
	alpha => 0,
	sequences => {
		click => {
			offset => [0, 0],
			clips => [3,135,25,19, 35,135,25,19, 67,135,25,19],
		},
		left => {
			offset => [0, -8],
			clips => [1,201,30,19, 33,201,30,19, 65,201,30,18],
		},
		right => {
			offset => [-29, -8],
			clips => [1,169,30,19, 33,169,30,19, 65,169,30,18],
		},
		forward => {
			offset => [-7, 0],
			clips => [8,5,16,22, 40,5,16,22, 72,5,16,22],
		},
		up => {
			offset => [-6, 0],
			clips => [9,97,14,30, 42,97,14,31, 75,98,13,29],
		},
		down => {
			offset => [-6, -28],
			clips => [9,66,14,29, 42,66,14,29, 75,66,13,28],
		},
	},
};

sub this_frame { int $_[0]->frame / 2 }
sub this_offset { $_[0]->this_sequences->{offset} }

sub sequence {
	my ($self) = @_;
	my $type = $;->cursor_type;
	my ($x, $y) = @{$self->pos};

	my $return;
	if($type eq 'click') {
		$return = 'click';
	}
	elsif($type eq 'out') {
		my $out = 80;
		$return =
			$x <  $out       ? 'left'  :
			$x >= 640 - $out ? 'right' : 'click';
	}
	else {
		my $middle;

		my $up_down = 50;
		if($type =~ /forward/) {
			$return = 'forward';
			$middle = 2;
		}
		if($type =~ /up/) {
			$return = 'up' if !$middle++ or $y < $up_down;
		}
		if($type =~ /down/) {
				$return = 'down'
			if !$middle
			or $middle == 1 and $y >= 480 / 2
			or $y >= 480 - $up_down
			;
			$middle = 1;
		}
		if($type =~ /sides/) {
			if($middle) {
				my $sides = 70;
				if   ($x <  $sides      ) { $return = 'left'  }
				elsif($x >= 640 - $sides) { $return = 'right' }
			}
			else {
				$return = $x < 640 / 2 ? 'left' : 'right';
			}
		}
	}
	wantarray ? ($return, $self->frame) : $return;
}

sub clicked {
	if(@_ > 1) { $_[0]->{clicked} = $_[1]; return $_[0]; }
	$_[0]->{clicked};
}

1;
