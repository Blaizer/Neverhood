=head1 NAME

Neverhood::Scene - the base class for all scenes

=cut

class Neverhood::Scene {
use Symbol qw/qualify/;

rw_ items      => sub { [] };
rw_ background => coerce => 1;
rw_ cursor     =>;
rw_ movie      => coerce => 1;
rw_ music      => coerce => 1;
rw_ klaymen    =>;
rw_ rect_list  => sub { [] };

method BUILD {
	$self->set_music($self->music) if defined $self->music;
	$self->set_background($self->background) if defined $self->background;
}
method first {
	Neverhood::App::set_frame_ticks(1000/24);
	$_->first for @{$self->items};
}
method next {
	$_->next for @{$self->items};
}
method last {}

method draw () {
	$_->draw for @{$self->items};
}
method render {}

method on_space {}

method _name_item ($name, $item) {
	return if !defined $name;
	if (!ref $name) {
		$self->{$name} = $item;
		$item->set_name($name) if !defined $item->name;
	}
	elsif (ref $name eq "SCALAR") {
		$$name = $item;
	}
	elsif (ref $name eq "ARRAY") {
		push @$name, $item;
	}
	else {
		confess "name must be undef, string, scalarref, or arrayref";
	}
}

method _item_index ($item) {
	my $index = 0;
	for (@{$self->items}) {
		return $index if $_ == $item;
		$index++;
	}
	return;
}

method add {
	my $name = shift;
	my $item;
	if (@_ & 1) {
		$item = shift;
	}
	else {
		$item = $name if defined $name and !ref $name;
	}

	if (defined $item and !ref $item) {
		my $caller = caller;
		$caller = $caller->scene if $caller->can("scene");
		$item = qualify $item, $caller;
		$item = $item->new(@_);
	}
	elsif (defined $item and blessed $item) {
		while (@_) {
			my $set = "set_".shift;
			my $val = shift;
			$item->$set($val);
		}
	}
	else {
		confess "item not defined or not blessed";
	}

	assert(blessed $item);
	confess "Trying to add duplicate item" if defined $self->_item_index($item);
	push @{$self->items}, $item;
	$self->_name_item($name, $item);
	$item->on_add if $item->can('on_add');
	return $item;
}

method remove ($item) {
	assert(blessed $item);
	my $index = $self->_item_index($item);
	return if !defined $index;
	splice @{$self->items}, $index, 1;
	$item->on_remove if $item->can('on_remove');
	return $item;
}

method replace ($item, $target_item) {
	return if !defined $target_item;
	assert(blessed $item and blessed $target_item);
	my $index = $self->_item_index($target_item);
	return if !defined $index;
	confess "Trying to add duplicate item" if defined $self->_item_index($item);
	splice @{$self->items}, $index, 1, $item;
	$item->_name_item($target_item->name, $item);
	$item->on_add if $item->can('on_add');
	$target_item->on_remove if $target_item->can('on_remove');
	return $item;
}

method add_sprite {
	my $name;
	$name = shift unless @_ & 1;
	my $sprite = shift;
	$sprite = Neverhood::Sprite->new(resource => $sprite, @_);
	$self->add($name, $sprite);
}

method add_sequence {
	my $name;
	$name = shift unless @_ & 1;
	my $sequence = shift;
	$sequence = Neverhood::Sequence->new(resource => $sequence, @_);
	$self->add($name, $sequence);
}

method _coerce_movie ($movie) {
	assert(defined $movie and !ref $movie || blesed $movie);
	if (!ref $movie) {
		$movie = Neverhood::MoviePlayer->new(resource => $movie);
	}

	$self->movie->stop if $self->movie;
	$self->replace($movie, $self->movie) or $self->add(movie => $movie);

	$movie;
}

method _coerce_background ($background) {
	assert(defined $background and !ref $background || blessed $background);
	if (!ref $background) {
		$background = Neverhood::Sprite->new(resource => $background);
	}
	$self->replace($background, $self->background) or $self->add(background => $background);
	$background->use_palette;
	$background->set_z(0);
	$background;
}

method _coerce_music ($music) {
	assert(defined $music and !ref $music || blessed $music);
	if (!ref $music) {
		$music = $;->load_music($music);
	}
	$music;
}

method add_klaymen {}

} 1;
