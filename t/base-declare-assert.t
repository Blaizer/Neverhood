use Neverhood::Base;
use Test::More;

ok eval { assert(1); 1 }, "pass 1";
ok !eval { assert(0); 1 }, "fail 0";

my $foo = 10;
sub foo { -10 }
ok eval { assert($foo + foo == 0); 1 }, "var+sub==0";
ok !eval { assert($foo + foo); 1 }, "!var+sub";
ok eval { assert(((+(($foo)) + (+foo)) == +(+0))); 1 }, "lotsa brackets var+sub==0";

$foo = 0;
ok !eval { assert(2/$foo); 1 }, "runtime error";

done_testing;
