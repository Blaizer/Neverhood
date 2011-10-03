#!/usr/bin/perl
use strict;
use warnings;
use lib 'inc';
use My::Module::Build;
use Alien::SDL;
use ExtUtils::CBuilder;

my @cflags = ( Alien::SDL->config('cflags'), File::Spec->catfile('-I' . Alien::SDL->config('prefix'), 'include') );
my @lflags = Alien::SDL->config('libs', '-lSDL_mixer');

my $build = My::Module::Build->new(
	module_name   => 'Games::Neverhood',
	dist_abstract => 'The Neverhood remade in SDL Perl',
	license       => 'perl',
	share_dir     => 'share',
	requires => {
		'perl'           => 5.010,
		'SDL'            => 2.534,
		'File::ShareDir' => 0,
	},
	configure_requires   => { 'Module::Build' => 0.38 },
	dynamic_config       => 1,
	extra_compiler_flags => \@cflags,
	extra_linker_flags   => \@lflags,
	include_dirs         => [ '.' ],
	typemap_files        => { 'typemap' => 'lib/Games/Neverhood/typemap' },
	add_to_cleanup => [
		'MANIFEST',
		'MANIFEST.bak',
		'META.yml',
		'META.json',
		'lib/Games/Neverhood/typemap',
	],
	meta_merge => {
		resources => {
			license    => 'http://dev.perl.org/licenses/',
			repository => 'http://github.com/Blaizer/Neverhood',
		},
	},
);

$build->add_build_element('typemap');
$build->create_build_script;

