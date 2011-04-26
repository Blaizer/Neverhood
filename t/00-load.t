use strict;
use warnings;
no warnings 'once';

use Test::More;

use_ok('Games::Neverhood');

$Games::Neverhood::Fullscreen = 0;
eval { Games::Neverhood::init(); };
ok(!$@, 'Games::Neverhood::init();');

isnt($Games::Neverhood::Folder, undef, 'Have a sharedir');

diag( "Testing Games::Neverhood $Games::Neverhood::VERSION, Perl $], $^X" );

done_testing;
