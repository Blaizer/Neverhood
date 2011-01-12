#!perl -T
use strict;
use warnings;
use Test::More;

use_ok('Games::Neverhood');

{
	no warnings 'once';
	isnt($Games::Neverhood::Folder, undef, 'Have a sharedir');
}

diag( "Testing Games::Neverhood $Games::Neverhood::VERSION, Perl $], $^X" );

done_testing;
