use strict;
use warnings;
use Test::More;
use Scalar::Util qw/weaken/;
use Storable qw/freeze thaw/;
use Games::Neverhood::OrderedHash;

ok(my $ref = Games::Neverhood::OrderedHash->new, 'new');
isa_ok($ref, 'Games::Neverhood::OrderedHash');
isa_ok(tied %{;do{no overloading; $ref->[0]}}, 'Games::Neverhood::OrderedHash::TiedHash');
isa_ok(tied @{;do{no overloading; $ref->[1]}}, 'Games::Neverhood::OrderedHash::TiedArray');

ok(!eval { untie %$ref }, '!untie %');
ok(!eval { untie @$ref }, '!untie @');

is_deeply([%{Games::Neverhood::OrderedHash->new([])}],                              [],                         '%([])');
is_deeply([%{Games::Neverhood::OrderedHash->new(undef)}],                           [],                         '%(undef)');
is_deeply([%{Games::Neverhood::OrderedHash->new([], 1..4, foo => 'bar')}],          [1..4, foo => 'bar'],       '%([], args)');
is_deeply([%{Games::Neverhood::OrderedHash->new(undef, [], {}, \1, undef, '', 1)}], [[], {}, \1, undef, '', 1], '%(undef, args)');

is_deeply(\@{Games::Neverhood::OrderedHash->new([])},                              [],             '@([])');
is_deeply(\@{Games::Neverhood::OrderedHash->new(undef)},                           [],             '@(undef)');
is_deeply(\@{Games::Neverhood::OrderedHash->new([], 1..4, foo => 'bar')},          [2,4,'bar'],    '@([], args)');
is_deeply(\@{Games::Neverhood::OrderedHash->new(undef, [], {}, \1, undef, '', 1)}, [{}, undef, 1], '@(undef, args)');

is_deeply([%{Games::Neverhood::OrderedHash->new([1,3])}],                [],                     '%([1,3])');
is_deeply([%{Games::Neverhood::OrderedHash->new([1,3], 1..4)}],          [1..4],                 '%([1,3], 1..4)');
is_deeply([%{Games::Neverhood::OrderedHash->new([], 1..4)}],             [1..4],                 '%([], 1..4)');
is_deeply([%{Games::Neverhood::OrderedHash->new(undef, 1..4)}],          [1..4],                 '%(undef, 1..4)');
is_deeply([%{Games::Neverhood::OrderedHash->new([1,5], 1..10)}],         [1,2,5,6,3,4,7,8,9,10], '%([1,5], 1..10)');
is_deeply([%{Games::Neverhood::OrderedHash->new([0,1,3,5,7], 1,2,5,6)}], [1,2,5,6],              '%([0,1,3,5,7], 1,2,5,6)');

is_deeply(\@{Games::Neverhood::OrderedHash->new([1,3])},                [undef, undef],          '@([1,3])');
is_deeply(\@{Games::Neverhood::OrderedHash->new([1,3], 1..4)},          [2,4],                   '@([1,3], 1..4)');
is_deeply(\@{Games::Neverhood::OrderedHash->new([], 1..4)},             [2,4],                   '@([], 1..4)');
is_deeply(\@{Games::Neverhood::OrderedHash->new(undef, 1..4)},          [2,4],                   '@(undef, 1..4)');
is_deeply(\@{Games::Neverhood::OrderedHash->new([1,5], 1..10)},         [2,6,4,8,10],            '@([1,5], 1..10)');
is_deeply(\@{Games::Neverhood::OrderedHash->new([0,1,3,5,7], 1,2,5,6)}, [undef,2,undef,6,undef], '@([0,1,3,5,7], 1,2,5,6)');

ok(!eval { Games::Neverhood::OrderedHash->new(0) },               '!(0)');
ok(!eval { Games::Neverhood::OrderedHash->new(0, 1..4) },         '!(0, 1..4)');
ok(!eval { Games::Neverhood::OrderedHash->new(1) },               '!(1)');
ok(!eval { Games::Neverhood::OrderedHash->new(1, 'foo', 'bar') }, '!(1, qw/foo bar/)');
ok(!eval { Games::Neverhood::OrderedHash->new(\1) },              '!(\1)');
ok(!eval { Games::Neverhood::OrderedHash->new(\1, [], {}) },      '!(\1, [], {})');
ok(!eval { Games::Neverhood::OrderedHash->new([1..5, 2]) },       '!order list dup');

$ref->{foo} = 1;
@$ref{qw/bar baz/} = (2, 3);
is_deeply([%$ref], [foo => 1, bar => 2, baz => 3], '%foo bar baz w/o initial elements');
is_deeply(\@$ref,  [1, 2, 3],                      '@foo bar baz w/o initial elements');

$ref->[0] = -1;
@$ref[1, 2] = (-2, -3);
is_deeply([%$ref], [foo => -1, bar => -2, baz => -3], '%foo bar baz flipped with tiedarray');
is_deeply(\@$ref,  [-1, -2, -3],                      '@foo bar baz flipped with tiedarray');

$ref->[-1] = undef;
@$ref[-2, -3] = ('foo', \1);
is_deeply([%$ref], [foo => \1, bar => 'foo', baz => undef], '%foo bar baz with tiedarray negative indexes');
is_deeply(\@$ref,  [\1, 'foo', undef],                      '@foo bar baz with tiedarray negative indexes');

ok(!eval { $ref->[3] = 0 }, "!index past end of array");
ok(!eval { $ref->[-4] = 0 }, "!index past start of array");

ok(scalar %$ref, '%scalar before clear gives true');
is(scalar @$ref, 3, '@scalar before clear gives 3');
undef %$ref;
is_deeply([%$ref], [],                    '%hash cleared');
is_deeply(\@$ref,  [undef, undef, undef], '@hash cleared');
ok(!scalar %$ref, '%scalar after clear gives false');
is(scalar @$ref, 3, '@scalar after clear gives 3');

$ref = Games::Neverhood::OrderedHash->new([qw/foo bar baz/], cake => 4, bar => 1, foobar => 5);
is_deeply([%$ref], [bar => 1, cake => 4, foobar => 5], '%bar cake foobar initial elements');
is_deeply(\@$ref,  [undef, 1, undef, 4, 5],            '@bar cake foobar initial elements');

$ref->{foo} = 1;
@$ref{qw/bar baz deadbeef/} = (2, 3, 6);
delete $ref->{foobar};
is_deeply([%$ref], [foo => 1, bar => 2, baz => 3, cake => 4, deadbeef => 6], '%foo bar baz cake foobar deadbeef all good');
is_deeply(\@$ref,  [1, 2, 3, 4, undef, 6],                                   '@foo bar baz cake foobar deadbeef all good');

$ref = thaw(freeze($ref));
isa_ok($ref, 'Games::Neverhood::OrderedHash');

my $complex = thaw(freeze([$ref, $ref]));
ok($complex->[0] == $complex->[1], 'Complex freeze worked');

$ref->[0] = 0;
@$ref[2, 5] = (-3, -6);
delete $ref->[1];
is_deeply([%$ref], [foo => 0, baz => -3, cake => 4, deadbeef => -6], '%foo bar baz cake foobar deadbeef all good');
is_deeply(\@$ref,  [0, undef, -3, 4, undef, -6],                     '@foo bar baz cake foobar deadbeef all good');

ok(exists $ref->{foo}, '%defined value exists');
ok(exists $ref->[0], '@defined value exists');
ok(!exists $ref->{foobar}, '%deleted value doesn\'t exist');
ok(!exists $ref->[4], '@deleted value doesn\'t exist');

is(shift @$ref, 0, 'shift works');
is(pop @$ref, -6, 'pop works');
is_deeply([%$ref], [baz => -3, cake => 4], '%shift and pop all good');
is_deeply(\@$ref,  [undef, -3, 4, undef],  '@shift and pop all good');

my @splice = splice @$ref, 2, 2;
is_deeply(\@splice, [4, undef],  'array context splice worked');
is_deeply([%$ref],  [baz => -3], '%splice all good');
is_deeply(\@$ref,   [undef, -3], '@splice all good');
ok(!defined(splice @$ref, 1, 0), 'scalar context splice worked');
ok(!eval {splice @$ref, 0, 0, 'asd'}, '!replacement list on splice');

ok(scalar %$ref, '%scalar before clear gives true');
is(scalar @$ref, 2, '@scalar before clear gives 2');
undef @$ref;
is_deeply([%$ref], [],             '%hash cleared');
is_deeply(\@$ref,  [undef, undef], '@hash cleared');
ok(!scalar %$ref, '%scalar after clear gives false');
is(scalar @$ref, 2, '@scalar after clear still gives 2');
splice @$ref;
is_deeply([%$ref], [], '%hash still cleared');
is_deeply(\@$ref,  [], '@hash fully cleared');
ok(!scalar %$ref, '%scalar after clear gives false');
is(scalar @$ref, 0, '@scalar after clear still gives 0');

ok(!eval {push @$ref, 'asd'}, 'push is illegal');
ok(!eval {unshift @$ref, 'sdf'}, 'unshift is illegal');

weaken(my $hash = tied(%{;do{no overloading; $ref->[0]}})->[0]);
weaken(my $array = tied(@{;do{no overloading; $ref->[1]}})->[0]);
ok(ref $hash, 'tiedhash referece made');
ok(ref $array, 'tiedarray reference made');
undef $ref;
ok(!ref $hash, 'tiedhash destroyed');
ok(!ref $array, 'tiedarray destroyed');

done_testing;
