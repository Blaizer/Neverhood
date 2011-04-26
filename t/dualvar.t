use strict;
use warnings;
use Test::More;
use Games::Neverhood::DualVar;

my $var = Games::Neverhood::DualVar->new;
ok($var == 0, 'default to 0');
ok($var eq '', "default to ''");

$var->set(1, 'foo');
ok($var == 1, 'numeric works');
ok($var eq 'foo', 'stringeric works');
ok(!($var cmp 'foo'), 'cmp works');

$var += 2;
ok($var == 3, '+= works');
ok(!($var - 3), '- and ! work');
ok($var & 3 == 3, '& works');
$var -= 3;
ok(!(cos($var) <=> 1), 'cos and <=> work');
$var -= 3;
ok(abs($var) == 3, 'abs works');
ok(-$var == 3, 'neg works');
ok($var++ == -2, 'post-increment');
ok($var == -2, 'post-increment works');
ok(++$var == -1, 'pre-increment works');
$var->set(3);
ok($var == 3 && $var eq 'foo', 'set really works');
$var &= 2;
ok($var == 2, '&= works');

$var .= 'bar';
ok($var eq 'foobar', '.= works');
ok($var . 'g' eq 'foobarg', '. works');
ok($var x 2 eq 'foobar' x 2, 'x works');

$var->set(1, '');
if($var and !"$var") { pass 'bool and set work' }
else { fail 'bool and set work' }

ok(!eval {$var->set('e')}, 'illegal number');
ok(!eval {$var->set(\1)}, 'illegal number');
ok(!eval {$var->set(undef, \1)}, 'illegal string');
ok(!eval {$var->set(0, '', 'dfg')}, 'illegal extra argument');

$var->set(3, 'foo');
$var->set;
ok($var == 3 && $var eq 'foo', 'no change with not exists');
$var->set(undef, undef);
ok($var == 3 && $var eq 'foo', 'no change with undefs');

done_testing;
