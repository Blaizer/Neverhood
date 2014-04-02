#!/usr/bin/env perl
# Build.PL - creates a build script to install Neverhood

# This software is copyright (c) 2013 by Blaise Roth.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
# See <http://dev.perl.org/licenses/> for more information.

use 5.01;
use strict;
use warnings;

use lib 'inc';
use My::Build;

use ExtUtils::CBuilder;
use Getopt::Long;

my $use_config = 1;
my $config = "sdl2-config";
my ($cflags, $libs);
GetOptions(
	"use-config"  => \$use_config,
	"use-alien"   => sub { $use_config = 0 },
	"config=s"    => sub { $config = $_[1]; $use_config = 1 },
	"cflags=s"    => \$cflags,
	"libs=s"      => \$libs,
	'help|h|?'    => sub { _exit_with_usage(0) },
) or _exit_with_usage(-1);

unless (defined $cflags and defined $libs) {
	if ($use_config) {
		my $lines = `$config --cflags --libs`;
		defined $lines or exit 1;
		my @line = split /\n/, $lines;
		@line < 2 and die "`$config --cflags --libs` didn't output 2 lines";
		$cflags //= $line[0];
		$libs   //= $line[1];
	}
	else {
		eval { require Alien::SDL2 } or die <<"ERROR";
		Build.PL requires Alien::SDL2 to be installed. Maybe try:
		$^X -MCPAN -e "install Alien::SDL2"
ERROR
		$cflags //= Alien::SDL2->config('cflags');
		$libs   //= Alien::SDL2->config('libs');
	}
}

my $cb = ExtUtils::CBuilder->new;
$cflags = [
	$cb->split_like_shell($cflags),
	qw/-std=c99 -Wall -Wextra -Wno-comment/,
];
$libs = [
	$cb->split_like_shell($libs),
];

my $build = My::Build->new(
	module_name    => 'Neverhood',
	license        => 'perl',
	release_status => 'unstable',
	configure_requires => {
		'perl'                  => 5.01,
		'Module::Build'         => 0.40,
		'Module::Build::XSUtil' => 0.01,
		'Alien::SDL2'           => 0.002,
		'ExtUtils::CBuilder'    => 0,
		'feature'               => 0,
		'strict'                => 0,
		'warnings'              => 0,
		'lib'                   => 0,
		'parent'                => 0,
		'File::Spec::Functions' => 0,
		'File::Path'            => 0,
		'File::Glob'            => 0,
		'File::Basename'        => 0,
		'File::Copy'            => 0,
		'GetOpt::Long'          => 0,
	},
	build_requires => {
		'perl'              => 5.01,
		'ExtUtils::ParseXS' => 3.16,
	},
	requires => {
		'perl'                 => 5.01,
		'Mouse'                => 1.12,
		'File::ShareDir'       => 1.00,
		'YAML::XS'             => 0.37,
		'Devel::Declare'       => 0.006011,
		'mro'                  => 0,
		'constant'             => 0,
		'Carp'                 => 0,
		'Symbol'               => 0,
		'Sub::Name'            => 0,
		'B::Hooks::EndOfScope' => 0,
		'Scalar::Util'         => 0,
		'List::Util'           => 0,
		'DynaLoader'           => 0,
		'Getopt::Long'         => 0,
		'Test::More'           => 0,
	},
	my_c_source          => { 'src' => 'blib/src' },
	typemap_files        => 'src/typemap',
	# share_dir            => 'share',
	extra_compiler_flags => $cflags,
	extra_linker_flags   => $libs,
	needs_compiler_c99   => 1,
	cc_warnings          => 0,
	add_to_cleanup => [
		'MANIFEST',
		'MANIFEST.bak',
		'META.*',
		'*_def.old',
		'compilet-*',
		'Neverhood-*',
	],
	meta_merge => {
		resources => {
			license    => 'http://dev.perl.org/licenses/',
			repository => 'http://github.com/Blaizer/Neverhood',
		},
	},
);

$build->create_build_script;

sub _exit_with_usage {
	my ($exitval) = @_;
	require Pod::Usage;
	require Pod::Find;
	my $input = Pod::Find::pod_where({-inc => 1}, __PACKAGE__);
	Pod::Usage::pod2usage(
		-input => $input,
		-verbose => 1,
		-exitval => $exitval,
	);
}

__END__

=head1 SYNOPSIS

perl Build.PL [options]

=head1 Options

 --use-config     Use sdl2-config instead of Alien::SDL2
 --use-alien      Use Alien::SDL2 instead of sdl2-config
 --config=FILE    Path to sdl2-config script
 --cflags=STR     Override cflags string
 --libs=STR       Override libs string
