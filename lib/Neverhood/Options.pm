=head1 NAME

Neverhood::Options - get and save options for Neverhood

=cut

role Neverhood::Options {

use Getopt::Long ();
use File::ShareDir ();
use File::Glob qw/bsd_glob/;
use File::Basename qw/basename/;
use YAML::XS qw/DumpFile LoadFile/;

rw data_dir   =>;
rw fullscreen =>;
rw width      =>;
rw height     =>;
rw frameless  =>;
rw resizable  =>;
rw vsync      =>;

rw debug =>;
rw mute  =>;
rw info  =>;

use constant share_dir => File::ShareDir::dist_dir('Neverhood');
use constant _config_file => catfile(share_dir, 'config.yaml');

my @_saved_options = qw/data_dir fullscreen frameless resizable vsync/;
my @_all_options   = (qw/debug mute info/, @_saved_options);

method new_from_options ($class:) {
	my $self = $class->new;

	my (%o, $config, $reset);
	Getopt::Long::Configure("bundling");
	Getopt::Long::GetOptions(
		'data-dir=s'            => \$o{data_dir},
		'cdrom|cd'              => sub { $o{data_dir} = "" },
		'fullscreen!'           => \$o{fullscreen},
		'frameless!'            => \$o{frameless},
		'resizable|resizeable!' => \$o{resizable},
		'vsync!'                => \$o{vsync},

		'reset'              => \$reset,
		'info!'              => \$o{info},
		'debug|d!'           => \$o{debug},
		'mute!'              => \$o{mute},
		'help|h|?'           => sub { _exit_with_usage(0) },
	) or _exit_with_usage(-1);

	$self->_mix_with_options(\%o, @_all_options);
	my $saved_o;

	if ($reset) {
		unlink $self->_config_file
		or open CLOBBER, ">", $self->_config_file and close CLOBBER;
	}
	else {
		$saved_o = $self->_mix_with_saved_options;
	}

	if (defined $self->data_dir) {
		my $data_dir = $self->data_dir;
		my ($valid, $cd) = $self->_data_dir_or_cd_is_valid($data_dir);

		if (!$valid) {
			die $cd ? "No valid CD found. Try again or specify --data-dir\n"
			        : "Data dir '$data_dir' is invalid\n";
		}
	}
	else {
		die "No data dir. Please use --data-dir or --cd to specify one\n";
	}

	$saved_o ||= {};
	DumpFile($self->_config_file, { map maybe($_ => $o{$_} // $saved_o->{$_}), @_saved_options });

	$self->_load_defaults_and_data_files;

	return $self;
}

method new_from_saved_options ($class:) {
	my $self = $class->new;
	my $saved_options = $self->_mix_with_saved_options;

	$saved_options
		or error "No saved options";

	$self->load;

	return $self;
}

method _mix_with_saved_options () {
	my $saved_options;
	eval { $saved_options = LoadFile($self->_config_file) };
	if ($saved_options and ref $saved_options eq 'HASH') {
		$self->_mix_with_options($saved_options, @_saved_options);
		return $saved_options;
	}
	return;
}

method load () {
	defined $self->data_dir
		or error "No data dir given";

	my ($valid, $cd) = $self->_data_dir_or_cd_is_valid($self->data_dir);
	$valid
		or error $cd ? "CD not found"
		             : "Invalid data dir";

	$self->_load_defaults_and_data_files;
}

method _load_defaults_and_data_files () {
	$self->_load_valid_data_files($self->share_dir);

	$self->_mix_with_options({
		fullscreen => 0,
		width      => 640,
		height     => 480,
		frameless  => 0,
		vsync      => 1,
		debug      => 0,
		mute       => 0,
	}, @_all_options);
}

method _mix_with_options ($options, @to_mix) {
	return if !$options;

	for my $opt (@to_mix) {
		my $val = $options->{$opt};
		if (defined $val and !defined $self->$opt) {
			my $set_opt = "set_$opt";
			if (!eval { $self->$set_opt($val); 1 }) {
				die "$opt could not be set to: $val. It must be of type: "
					. $self->meta->get_attribute($opt)->{isa};
			}
		}
	}
}

method _data_dir_or_cd_is_valid ($data_dir) {
	my $valid;
	my $cd = 1;

	if ($data_dir eq "") { # check CD drives for data dir
		# while (defined(my $cd_name = Neverhood::App::get_next_cd_name)) {
		# 	if ($valid = $self->_data_dir_is_valid($cd_name, $cd = 1)) {
		# 		last;
		# 	}
		# }
	}
	else { # check string for being data dir
		$valid = $self->_data_dir_is_valid($data_dir, $cd = 0);
	}

	return $valid, $cd;
}

method _data_dir_is_valid ($data_dir, $cd) {
	my @dirs = ($data_dir);
	my $data_dir_2 = catdir($data_dir, "DATA");

	if (-d $data_dir) {
		if (-d $data_dir_2) {
			if ($cd) { unshift @dirs, $data_dir_2 }
			else     { push    @dirs, $data_dir_2 }
		}
	}
	else {
		say STDERR "Directory '$data_dir' does not exist." if !$cd;
		return;
	}

	for my $dir (@dirs) {
		$self->set_data_dir($dir);
		if ($self->_load_valid_data_files($dir)) {
			return 1;
		}
	}
	return;
}

method _load_valid_data_files ($dir) {
	my $valid;
	my @files = bsd_glob catfile($dir, "*.[Bb][Ll][Bb]");

	for my $filename (@files) {
		$valid = 1 if $self->load_archive($filename);
	}

	return $valid;
}

func _exit_with_usage ($exitval) {
	require Pod::Usage;
	require Pod::Find;
	my $input = Pod::Find::pod_where({-inc => 1}, __PACKAGE__);
	Pod::Usage::pod2usage(
		-input => $input,
		-verbose => 1,
		-exitval => $exitval,
	);
}

}1;

__END__

=head1 SYNOPSIS

nhc [options]

=head1 Options

 --data-dir=DIR     Set the data dir (BLB files)
 --cdrom --cd       Search for the data dir on your CD drives
 --fullscreen       Run the game fullscreen
 --frameless        Run the game in a frame-less window
 --resizable        Allow the window to be resizable
 --vsync            Limit the FPS to hardware limit (default)

 --reset            Reset any saved options to default
 -d --debug         Enable all debugging features
 --mute             Mute all music and sound
 -? -h --help       Show this help

=head1 Cheats

 FASTFORWARD             Toggle fast sprite animation
 SCREENSNAPSHOT          Save a screenshot to ./NevShot.bmp
 HAPPYBIRTHDAYKLAYMEN    Skip the Nursery (the first room)
 LETMEOUTOFHERE          Skip the Nursery Lobby (the second room)
 PLEASE                  Solve the puzzle in the Dynamite Shack
