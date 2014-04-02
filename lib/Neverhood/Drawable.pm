role Neverhood::Drawable {
requires qw/draw_surface draw_x draw_y/;

rw visible => 1;
rw name =>;
rw z =>;

my @_draw_queue;

# Draw using Schwartzian transform
method draw () {
	return if !$self->visible;
	warn $self->any_name . " didn't define draw_z" if !defined $self->draw_z;
	push @_draw_queue, [$self->draw_z//0, $self, $self->draw_x, $self->draw_y];
}

func draw_all () {
	for (sort { $a->[0] <=> $b->[0] } @_draw_queue) {
		$_->[1]->draw_surface($_->[2], $_->[3]);
	}
	@_draw_queue = ();
}

map { $_->[1] } sort { $a->[0] <=> $b->[0] } map { [ monkeys($_), $_ ] } @list;

method draw_z () {
	$self->z;
}

method any_name () {
	return $self->name if defined $self->name;
	return '' if !$self->resource;
	return $self->resource->key;
}

} 1;
