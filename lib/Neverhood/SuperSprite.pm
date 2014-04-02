class Neverhood::SuperSprite {
extends Neverhood::Blitter;
with Neverhood::Drawable;

rw resource =>;
rw [<x y>] => 0;

Mouse::has surface   => is => 'bare';
Mouse::has clip_rect => is => 'bare';
Mouse::has src_rect  => is => 'bare';
Mouse::has flip      => is => 'bare';
Mouse::has flip_y    => is => 'bare';
Mouse::has repl      => is => 'bare';

method BUILDARGS {
	if (@_ == 1 and ref $_[0] ne "HASH" or @_ > 1 and @_ & 1) {
		return { resource => @_ };
	}
	else {
		return $self->next::buildargs(@_);
	}
}

method BUILD ($args) {
	$self->set_resource($self->resource);

	$self->set_surface   (delete $self->{surface})   if exists $self->{surface};
	$self->set_clip_rect (delete $self->{clip_rect}) if exists $self->{clip_rect};
	$self->set_src_rect  (delete $self->{src_rect})  if exists $self->{src_rect};
	$self->set_flip      (delete $self->{flip})      if exists $self->{flip};
	$self->set_flip_y    (delete $self->{flip_y})    if exists $self->{flip_y};
	$self->set_repl    (@{delete $self->{repl}})     if exists $self->{repl};
}

method draw_surface ($x, $y) {
	return if !$self->surface_resource;
	$self->surface_resource->load_surface($self->surface, $self->flip, $self->flip_y);
	$self->do_repl;
	$self->next::method($x, $y, $self->w, $self->h);
}

method draw_x () {
	if ($self->flip) {
		return $self->x - $self->offset_x - $self->w + 1;
	}
	else {
		return $self->x + $self->offset_x;
	}
}

method draw_y () {
	if ($self->flip_y) {
		return $self->y - $self->offset_y - $self->h + 1;
	}
	else {
		return $self->y + $self->offset_y;
	}
}

} 1;
