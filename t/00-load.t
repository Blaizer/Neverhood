use 5.01;
use strict;
use warnings;
no warnings 'once';

use Test::More;

use_ok('Games::Neverhood');

$Games::Neverhood::Fullscreen = 0;
eval { Games::Neverhood->new };
is( $@, undef, 'Games::Neverhood->new' );

isnt( $Games::Neverhood::ShareDir, undef, 'Have a share dir' );

diag( "Testing Games::Neverhood $Games::Neverhood::VERSION, Perl $], $^X" );

done_testing;
