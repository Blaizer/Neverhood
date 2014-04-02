use 5.01;
use strict;
use warnings;

use Test::More;

use_ok 'Neverhood';

Neverhood->new;

isa_ok $;, 'Neverhood', "Game object created";

undef $;;
pass "Game object destroyed";

diag "Testing Neverhood $Neverhood::VERSION, $^X $]";

done_testing;
