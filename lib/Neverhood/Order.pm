=head1 NAME

Neverhood::Order - a list of values ordered by z values

=head1 DESCRIPTION

Items are added to the list one by one. Higher up items (items with larger z values) are earlier in the list. If an item is added with the same z value as something already in the list, it will be added above it. If you add a value with an undefined z value, then it will be added to the top of the list (and given the same z value as the previous top value or 0).

You can add any defined value to the list, but you can only remove blessed values. If you add the same blessed value to the list twice, the first instance of it will be removed from the list. This isn't done for non-blessed values.

=cut

package Neverhood::Order;

use Neverhood::Base;

use constant {
	Z => 0,
	VALUE => 1,
};

method new ($class:) {
	bless [], $class;
}

method values () {
	map $_->[VALUE], @$self;
}

method add (Defined $item, Maybe[Int] $z?) {
	$self->remove($item) if blessed $item;

	my $i = 0;
	if (defined $z) {
		for (; $i < @$self; $i++) {
			last if $self->[$i][Z] <= $z;
		}
	}
	else {
		$z = @$self ? $self->[0][Z] : 0;
	}
	splice @$self, $i, 0, [$z, $item];
	return $item;
}

method remove (Object $item) {
	my $item_index = $self->_index_of($item);
	return if !defined $item_index;
	splice @$self, $item_index, 1;
	return $item;
}

method replace (Object $item, Maybe[Object] $target_item) {
	return if !defined $target_item;
	my $target_index = $self->_index_of($target_item);
	return if !defined $target_index;
	$self->remove($item);
	splice @$self, $target_index, 1;
	return $item;
}

method _index_of (Object $item) {
	while (my ($i, $entry) = each @$self) {
		return $i if $entry->[VALUE] == $item;
	}
	return;
}

no Neverhood::Base;
1;
