class Neverhood::Global {
use Storable qw/store retrieve/;

rw door_busted =>;
rw window_open =>;

method load ($file) {
	my $hash = retrieve($file);
	$hash && ref $hash eq "HASH"
		or die "Couldn't load $file";

	$self->new(
		map valid_value($hash->{$_}), $self->meta->get_attribute_list,
	);
}

method save ($file) {
	my $hash = {
		map valid_value($self->$_), $self->meta->get_attribute_list,
	};
	store($hash, $file);
}

func valid_value ($val) {
	return if !$val
		or ref $val and not
			ref $val eq "ARRAY" && @$val ||
			ref $val eq "HASH"  && %$val;

	($_ => $val);
}

} 1;
