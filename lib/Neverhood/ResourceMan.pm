=head1 NAME

Neverhood::ResourceMan - manages loading and unloading of resources from archives

=cut

role Neverhood::ResourceMan {

rw_ _entries   => sub { {} };
rw_ _resources => sub { {} };
rw_ _files     => sub { [] };
rw_ _archives  => sub { {} };

method load_archive ($filename) {
	state $virgin = 1;

	my $size;
	if (!-f $filename or ($size = -s _) <= 0) {
		return;
	}

	if (!open FILE, "<", $filename) {
		say STDERR "Couldn't open $filename: $!";
		return;
	}

	binmode FILE;
	my $read = read FILE, my $data, 16;
	close FILE;

	if (!defined $read) {
		say STDERR "Couldn't read from $filename: $!";
		return;
	}

	if ($read < 16) {
		say STDERR "$filename is invalid";
		return;
	}

	my ($id1, $id2, $ext_data_size, $file_size, $file_count) = unpack '(LSsll)<', $data;
	if ($id1 != 0x2004940 or $id2 != 7) {
		say STDERR "$filename is invalid";
		return;
	}

	my $ext_data_pos = 16 + $file_count * (4 + 20);
	if ($file_size != $size or $ext_data_pos + $ext_data_size > $file_size) {
		say STDERR "$filename is corrupt";
		return;
	}

	if ($self->info) {
		my $data_dir  = $self->data_dir;
		my $share_dir = $self->share_dir;
		if ($virgin) {
			say " Data dir: $data_dir\nShare dir: $share_dir";
			say "Data files:";
		}
		my $name = $filename;
		$name =~ s/^$data_dir/<Data dir>/
		or $name =~ s/^$share_dir/<Share dir>/;
		say "\t$name";
	}

	push @{$self->_files}, $filename;
	my $archive = Neverhood::Archive->new($self->_files->[-1]);
	$archive
		or error "Couldn't load archive: $filename";

	$self->_archives->{$filename} = $archive;

	while ((my $entry = $archive->next_entry)) {
		# keys are formatted as 8 uppercase hex digits
		my $existing_entry = \$self->_entries->{$entry->key};

		unless ($$existing_entry and $$existing_entry->time_stamp > $entry->time_stamp) {
			# put the entry in the hash
			$$existing_entry = $entry;
		}
	}

	undef $virgin;
	return 1;
}

method get_entry ($key) {
	my $entry = $self->_entries->{$key}
		or error "Couldn't get entry with key: '$key'";

	# redirect dummy entry
	while ($entry->compr_type == 0x65) {
		# get the entry that the dummy entry points to
		my $next_key = Neverhood::ArchiveEntry::key_from_int($entry->disk_size);
		my $next_entry = $self->_entries->{$next_key};
		$next_entry
			or error "Couldn't redirect key $key to $next_key";

		$entry->redirect($next_entry);
	}

	return $entry;
}

# conversion table with placeholders
my @_type_names = (qw/ ? ? Sprite Palette Sequence ? ? Sound Music ? Smacker /);

method _load_resource ($key, $entry) {
	my $resource;
	# unless ($resource = $self->_resources->{$key}) {
		my $class = $_type_names[$entry->type];
		$class = "Neverhood::${class}Resource";
		$resource = $class->new($entry);

		# if (defined $resource) {
		# 	weaken($self->_resources->{$key} = $resource);
		# }
		# else {
		# 	$self->_resources->{$key} = $resource;
		# }
	# }
	return $resource;
}

method _load_resource_of_type ($key, $type) {
	my $entry = $self->get_entry($key);
	$entry or error("Key %08X is not in entry hash", $key);
	$entry->type == $type or error("Trying to load type %d as type %d", $entry->type, $type);
	return $self->_load_resource($key, $entry);
}

method clean_destroyed_resources () {
	while (my ($key, $value) = each %{$self->_resources}) {
		delete $self->_resources->{$key} if !defined $value;
	}
}

method load_sprite   ($key) { $self->_load_resource_of_type($key, 2) }
method load_sequence ($key) { $self->_load_resource_of_type($key, 4) }
method load_music    ($key) { $self->_load_resource_of_type($key, 8) }
method load_smacker  ($key) { $self->_load_resource_of_type($key, 10) }

method load_palette ($key) {
	my $entry = $self->get_entry($key);
	$entry or error("Key %08X is not in entry hash", $key);
	return $self->_load_resource($key, $entry) if $entry->type == 3;
	return $self->_load_resource($key, $entry)->palette if $entry->type == 2 || $entry->type == 4;
	error("Trying to load type %d as type 2/3/4", $entry->type);
}

method play_sound ($key, $loops, $timeout) {
	my $entry = $self->get_entry($key);
	$entry or error("Key %08X is not in entry hash", $key);
	$entry->type == 7 or error("Trying to play type %d as type 7", $entry->type);
	return Neverhood::SoundPlayer->play($entry, $loops, $timeout);
}

} 1;
