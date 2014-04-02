=head1 NAME

Neverhood::Sequence - drawable sequence of frames

=cut

class Neverhood::Sequence {
extends Neverhood::SuperSprite;

rw_ _frame =>;
rw cur_frame => 0;
rw cur_frame_ticks => -1;
rw stick_frame => -2;
rw last_frame => -1;
rw first_frame => -1;
rw changed => 0;
rw looped => 0;
rw play_direction => 1;

method surface_resource {
	return $self->_frame;
}

# trigger resource {
# 	say $self->resource;
# 	if (ref $self->resource) {
# 		$self->_change_frame;
# 	}
# }
around set_resource ($new) {
	say $self->resource;
	if (!ref $new) {
		$self->$orig($;->load_sequence($new));
	}
	say $self->resource;
}

method frame_count {
	$self->resource or return;
	$self->resource->frame_count;
}

method frame_ticks {
	$self->_frame or return;
	$self->_frame->ticks;
}
method offset_x {
	$self->_frame or return;
	$self->_frame->offset_x;
}
method offset_y {
	$self->_frame or return;
	$self->_frame->offset_y;
}
method w {
	$self->_frame or return;
	$self->_frame->w;
}
method h {
	$self->_frame or return;
	$self->_frame->h;
}
method frame_delta_x {
	$self->_frame or return;
	$self->_frame->delta_x;
}
method frame_delta_y {
	$self->_frame or return;
	$self->_frame->delta_y;
}
method collision_offset {
	$self->_frame or return;
	$self->_frame->collision_offset;
}
method collision_rect {
	$self->_frame or return;
	my $offset = $self->collision_offset;

	return [
		$self->draw_x - $self->offset_x + $offset->[0],
		$self->draw_y - $self->offset_y + $offset->[1],
		$offset->[2],
		$offset->[3]
	];
}

after set_cur_frame {
	$self->_change_frame;
}

method draw_rect {
	[ $self->draw_x, $self->draw_y, $self->w, $self->h ];
}

around stick_frame {
	my $stick_frame = $self->$orig(@_);
	return $stick_frame if $stick_frame >= 0;
	return $self->last_frame if $stick_frame == -1;
	return $stick_frame;
}
around first_frame {
	my $first_frame = $self->$orig(@_);
	return $first_frame if $first_frame >= 0;
	return 0;
}
around last_frame {
	my $last_frame = $self->$orig(@_);
	return $last_frame if $last_frame >= 0;
	return $self->frame_count - 1 if defined $self->frame_count;
	return;
}

method first () {
	$self->_change_frame;
}

method next () {
	$self->set_changed(0);
	$self->set_looped(0);

	my $ticks = $self->cur_frame_ticks + 1;

	if ($ticks >= ($self->frame_ticks // 1)) {
		if ($self->cur_frame != $self->stick_frame) {
			$self->set_cur_frame_ticks(0);

			$self->set_changed(1);

			my $frame = $self->cur_frame + $self->play_direction;

			if ($self->play_direction >= 0) {
				if ($frame > $self->last_frame) {
					$frame = $self->first_frame;
					$self->set_looped(1);
				}
			}
			elsif ($frame < $self->first_frame) {
				$frame = $self->last_frame;
				$self->set_looped(1);
			}

			$self->set_cur_frame($frame);
		}
	}
	else {
		$self->set_cur_frame_ticks($ticks);
		$self->_change_frame if !defined $self->_frame;
	}
}

method _change_frame () {
	return if !$self->resource;
	my $frame = $self->resource->frame($self->cur_frame);
	return if $self->_frame and $frame == $self->_frame;
	$self->_set_frame($frame);
	$self->set_src_rect([0, 0, $self->w, $self->h]);

	say sprintf "%s: %08X %04X", $self->any_name, $frame->frame_key, $frame->unused;

	# $self->_next_delta;
}

method _next_delta () {
	$self->set_x($self->x + ($self->flip   ? -$self->frame_delta_x : $self->frame_delta_x));
	$self->set_y($self->y + ($self->flip_y ? -$self->frame_delta_y : $self->frame_delta_y));
}

} 1;
