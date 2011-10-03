package My::Module::Build;
use strict;
use warnings;
use base 'Module::Build';
use autodie ':all';

$ENV{SDL_VIDEODRIVER} = 'dummy';
$ENV{SDL_AUDIODRIVER} = 'dummy';

sub ACTION_uninstall {
	require File::ShareDir;
	require File::Spec;
	eval { require Games::Neverhood };
	$! and leave("Games::Neverhood wouldn't load: $@. Maybe install before uninstalling?");
	my $dir = File::ShareDir::module_dir('Games::Neverhood');
	my $packlist = File::Spec->catfile($dir, '.packlist');
	open LIST, ">>$packlist"; #Just makin' sure we can write in it later
	open LIST, $packlist;
	my $leftover;
	my $total = my $deleted = 0;
	print "Deleting all files listed in $packlist\n";
	while(<LIST>) {
		chomp;
		no autodie;
		if(unlink) {
			$deleted++;
		}
		elsif(-e) {
			STDERR->print("Couldn't delete $_: $!\n");
			$leftover .= "$_\n";
		}
		else {
			$total--;
		}
		$total++;
	}
	if(defined $leftover and $deleted) {
		print "$deleted of $total files successfully deleted\n";
		print "Updating .packlist with remaining files\n";
		open LIST, ">$packlist";
		print LIST $leftover;
		print ".packlist updated with remaining files\n";
	}
	else {
		print "all files successfully deleted\n";
		if(do { no autodie; unlink $packlist }) {
			print ".packlist deleted\n";
		}
		else {
			open LIST, ">$packlist";
			print ".packlist emptied\n";
		}
	}
	close LIST;
}

sub leave {
	STDERR->print($_[0], "\n");
	exit;
}

1;
