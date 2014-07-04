=head1 NAME

Neverhood::Sprite - drawable single image sprites

=cut

class Neverhood::Sprite {
extends Neverhood::SuperSprite;

rw [<x y>] => 0, check => 1;
rw resource => coerce => 1, check => 1;
rw [<offset_x offset_y>] => 0;
rw_ _default_pos => 1;

method surface_resource {
	return $self->resource;
}

method reset_pos () {
	$self->resource or return;
	$self->set_x($self->resource->x);
	$self->set_y($self->resource->y);
	$self->_set_default_pos(1);
}

method _coerce_resource ($new) {
	return $new if !defined $new or blessed $new;
	assert(!ref $new);
	$;->load_sprite($new);
}

method _check_resource {
	if (ref $self->resource) {
		$self->reset_pos if $self->_default_pos;
	}
}

method _check_x__y {
	$self->_set_default_pos(0);
}

method w {
	$self->resource or return;
	$self->resource->w;
}
method h {
	$self->resource or return;
	$self->resource->h;
}

method draw_rect {
	[ $self->draw_x, $self->draw_y, $self->w, $self->h ];
}

method use_palette {
	$self->resource->use_palette;
}

method first {}
method next {}

} 1;
