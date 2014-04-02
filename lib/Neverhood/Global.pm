class Neverhood::Global {
use Storable qw/store retrieve/;

rw door_busted =>;
rw window_open =>;

method load ($file) {
	my $hash = retrieve($file);
	for ($self->meta->get_attribute_list) {
		my $val = valid_value($hash->$_);
		next if !$val;
		my $set = "set_$_";
		$self->$set($val);
	}
}

method save ($file) {
	my $hash = {
		map valid_value($self->$_), $self->meta->get_attribute_list,
	};
	store($hash, $file);
}

func valid_value ($val) {
	return if !$val;
	!ref $val
	||
	(ref $val eq "ARRAY" && @$val || ref $val eq "HASH" && %$val)
		? ($_ => $val)
		: ();
}

} 1;
