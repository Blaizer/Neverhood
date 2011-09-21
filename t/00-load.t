use 5.01;
use strict;
use warnings;
no warnings 'once';

use Test::More;

$Games::Neverhood::Fullscreen = 0;
$Games::Neverhood::NoFrame = 0;
use_ok('Games::Neverhood');

isnt( $Games::Neverhood::ShareDir, undef, 'Have a share dir' );

diag( "Testing Games::Neverhood $Games::Neverhood::VERSION, Perl $], $^X" );

done_testing;
