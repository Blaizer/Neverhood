#!/usr/bin/env perl
use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
	module_name   => 'Games::Neverhood',
	license       => 'perl',
	share_dir     => 'DATA',
	requires => {
		'perl'           => 5.010,
		'Alien::SDL'     => 1.414,
		'SDL'            => 2.518,
		'Test::More'     => 0,
		'File::ShareDir' => 0,
	},
	recommends => {
	},
	meta_merge => {
		resources => {
			license    => 'http://dev.perl.org/licenses/',
			repository => 'http://github.com/Blaizer/Neverhood',
		},
	},
	add_to_cleanup => [
	],
);

$build->create_build_script;
