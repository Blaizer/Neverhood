use Neverhood::Base;
use Test::More;

ok eval { assert(1); 1 }, "pass 1";
diag $@ if $@;
ok !eval { assert(0); 1 }, "fail 0";
diag $@ if $@;

my $foo = 10;
sub foo { -10 }
ok eval { assert($foo + foo == 0); 1 }, "var+sub==0";
diag $@ if $@;
ok !eval { assert($foo + foo); 1 }, "!var+sub";
diag $@ if $@;
ok eval { assert(((+(($foo)) + (+foo)) == +(+0))); 1 }, "lotsa brackets var+sub==0";
diag $@ if $@;

$foo = 0;
ok !eval { assert($bar = 2); 1 }, "strict error";
diag $@ if $@;
ok !eval { assert(2/$foo); 1 }, "runtime error";
diag $@ if $@;

done_testing;
