=head1 NAME

Neverhood::Sprite - drawable single image sprites

=cut

class Neverhood::Sprite {
extends Neverhood::SuperSprite;

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

trigger resource {
	if (ref $self->resource) {
		$self->reset_pos if $self->_default_pos;
	}
}
around set_resource ($new) {
	say $self->resource;
	if (!ref $new) {
		$self->$orig($;->load_sprite($new));
	}
	say $self->resource;
}

trigger [<x y>] {
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
