use 5.01;
use strict;
use warnings;

package My::Build;
use parent 'Module::Build::XSUtil';

use File::Spec::Functions;
use File::Path 'make_path';
use File::Glob 'bsd_glob';
use File::Basename;
use File::Copy 'copy';

# Complete override of process_support_files to do things a different way.
# C files in my_c_source are checked for a MODULE = ... line. If they have
# that then they're processed as XS, then processed as C. Otherwise they're
# processed normally
sub process_support_files {
	my $self = shift;
	my $p = $self->{properties};
	return if !$p->{my_c_source};

	my $c_source = $p->{my_c_source};
	my $typemap_files = $p->{typemap_files};
	$typemap_files = [$typemap_files] if !ref $typemap_files;

	for (keys %$c_source) {
		push @{$p->{include_dirs}}, $self->localize_dir_path($_);
	}

	for my $path (keys %$c_source) {
		my $dir  = $self->localize_dir_path($path);
		my $bdir = $self->localize_dir_path($c_source->{$path}); # build dir

		next if !-d $dir;

		my $qr_ext = $self->file_qr('\.c$');
		my @files = @{ $self->rscan_dir($dir, $qr_ext) };

		my $err;
		make_path $bdir, {error => \$err};
		@$err and die "Couldn't make path to $bdir";
		$self->add_to_cleanup($bdir);

		for my $typemap (@$typemap_files) {
			next if !-f $typemap;
			$self->copy_if_modified(from => $typemap, to => catfile($bdir, basename $typemap));
		}

		for my $file (@files) {
			open FILE, "<", $file
				or die "Couldn't open $file for reading";

			while (<FILE>) {
				if (/^MODULE\s*=\s*[\w:]+(?:\s+PACKAGE\s*=\s*[\w:]+)?(?:\s+PREFIX\s*=\s*\S+)?\s*$/) {
					# c file is an xs file
					close FILE;

					my ($name, undef, $ext) = fileparse $file, $qr_ext;
					my $bfile = catfile $bdir, "$name.xs";

					# copy .c to build/.xs
					$self->add_to_cleanup($bfile);
					$self->copy_if_modified(from => $file, to => $bfile);

					$file = catfile $bdir, $name.$ext;

					# compile build/*.xs to build/*.c
					$self->add_to_cleanup($file);
					if (!$self->up_to_date($bfile, $file)) {
						$self->compile_xs($bfile, outfile => $file);
					}

					last;
				}
			}
			close FILE;

			push @{$p->{objects}}, $self->compile_c($file);
		}
	}
}

=head1 ACTIONS

=over

=item run

[version 0.24] (Blaise Roth)

This action will build, install, and run Neverhood for you. Arguments passed
to this action will be given verbatim to the run program. This action is more
for speedy testing purposes. Several options, such as --debug, are specified
for you by default. It also passes --run to the "build" action in order to
disable some compiler warnings of the "unused" category that get in the way of
development.

=back

=cut

sub ACTION_run {
	my $self = shift;

	# specify --run to build action
	$self->{args}{run} = undef;

	# any stderr is fatal
	require Capture::Tiny;
	my $stderr = Capture::Tiny::tee_stderr(sub {
		$self->depends_on('build');
	});
	if (defined $stderr and length $stderr) {
		chomp $stderr;
		die "\n$stderr\n";
	}

	$self->depends_on('install');

	my $nhc = catfile qw(bin nhc);
	my @args = qw(--debug --noframeless --resizable --nofullscreen --novsync);
	shift @ARGV; # remove 'run' from args to pass to nhc

	say '=' x 79;
	$self->do_system($^X, $nhc, @args, @ARGV);
	say '-' x 79;
}

# small overload to disable some warnings when --run is passed to build
sub ACTION_build {
	my $self = shift;

	if (exists $self->{args}{run}) {
		push @{$self->{properties}{extra_compiler_flags}},
			qw(-Wno-unused -Wunused-result -Wunused-value);
	}

	$self->SUPER::ACTION_build(@_);
}

=over

=item license

[version 0.33] (Blaise Roth)

This action will generate a copy of this distribution's license. This requires
Software::License to be installed. It will write it into a file called LICENSE
in the current directory. BEWARE: it will overwrite the file if it already
exists (if it can). It will also print out the notice and URL for the license.

=back

=cut

sub ACTION_license {
	my $self = shift;

	# Code modified from sub _software_license_object in Module::Build::Base

	my $license = $self->license
		or die "Dist has no license";

	require Software::License;

	my $class;
	for my $l ($self->valid_licenses->{$license}, $license) {
		next unless defined $l;
		my $trial = "Software::License::" . $l;
		if (eval "require $trial") {
			$class = $trial;
			last;
		}
	}
	defined $class
		or die "Couldn't find Software::License module for $license";

	my $author = join " & ", map { s/\s*<.*>$//; $_ } @{$self->dist_author};
	my $sl;
	eval { $sl = $class->new({ holder => $author }); 1 }
		or die "Error getting '$class' object: $@";

	open LICENSE, ">", catfile('LICENSE')
		or die "Could not open ./LICENSE for writing";

	my $fulltext = $sl->fulltext;
	my $notice = $sl->notice;

	s/copyright \(c\)/Copyright (C)/gi for $fulltext, $notice; # for consistency

	$fulltext =~ s/\h+$//gm; # remove whitespace from the end of all lines
	$fulltext =~ s/\n+$//;   # remove newlines from the end
	say LICENSE $fulltext;   # add back one newline to the end

	say $notice;
	say $sl->url;
}

=over

=item ppport

[version 0.12] (Blaise Roth)

This action will run the ppport.h script (see Devel::PPPort) on all of
Neverhood's C and XS source files.

If the option --write is specified, this action will instead generate a new
ppport.h script. This requires Devel::PPPort to be installed. BEWARE: it will
overwrite the file if it already exists (if it can).

=back

=cut

sub ACTION_ppport {
	my $self = shift;

	my $dir = catdir "src";
	my $name = "ppport.h";

	if (exists $self->{args}{write}) {
		chdir $dir or die "Couldn't chdir $dir: $!";
		require Devel::PPPort;
		Devel::PPPort::WriteFile($name);
	}
	else {
		my $ppport = catfile($dir, $name);
		my $dirs = join ",",
			keys %{$self->{properties}{my_c_source}},
		;
		my @files = bsd_glob catfile "{$dirs}", "*.{c,h,xs}";
		$self->do_system($^X, $ppport, "--compat-version=5.10.0", "--cplusplus", @files);
	}
}

1;
