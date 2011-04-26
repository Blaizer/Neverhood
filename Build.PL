#!/usr/bin/perl
use strict;
use warnings;
use lib 'inc';
use My::Module::Build;

my $build = My::Module::Build->new(
	module_name   => 'Games::Neverhood',
	license       => 'perl',
	share_dir     => 'share',
	requires => {
		'perl'           => 5.01,
		'SDL'            => 2.526,
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
