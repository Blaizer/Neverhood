package My::Module::Build;
use strict;
use warnings;
use base 'Module::Build';
use autodie ':all';

sub ACTION_uninstall {
	require File::ShareDir;
	require File::Spec;
	eval { require Games::Neverhood };
	$! and leave("Games::Neverhood wouldn't load: $@. Maybe install before uninstalling?");
	my $packlist = File::Spec->catfile(
		File::ShareDir::module_dir('Games::Neverhood'),
		'.packlist'
	);
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
	print "$deleted of $total files successfully deleted\n";
	if(defined $leftover and $deleted) {
		print "Updating .packlist with remaining files\n";
		open LIST, ">$packlist";
		print LIST $leftover;
		print ".packlist updated with remaining files\n";
	}
	else {
		if(do { no autodie; unlink $packlist }) {
			print ".packlist deleted\n";
		}
		else {
			print "Emptying .packlist\n";
			open LIST, ">$packlist";
		}
	}
	close LIST;
}

sub leave {
	STDERR->print($_[0], "\n");
	exit;
}

1;
