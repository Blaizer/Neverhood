use Neverhood::Base;
use Test::More;

class Foo {
	rw foo =>
		constraint => sub { $_[0] > 10 };

	rw bar =>
		constraint => sub { $_[0] < 10 },
		coerce => sub { $_[0] + 2 };

	rw baz =>
		coerce => sub { $_[0] - 5 };
}

{
	my $foo;

	$foo = Foo->new(foo => 12);
	is $foo->foo, 12, "set foo in constructor";

	$foo = Foo->new(bar => 7);
	is $foo->bar, 9, "set bar in constructor";

	$foo = Foo->new(baz => 7);
	is $foo->baz, 2, "set baz in constructor";

	ok !eval { Foo->new(foo => 10); 1 }, "setting foo in constructor failed";

	ok !eval { Foo->new(bar => 8); 1 }, "setting bar in constructor failed";
}

{
	my $foo = Foo->new;

	$foo->set_foo(11);
	is $foo->foo, 11, "set foo";

	$foo->set_bar(6);
	is $foo->bar, 8, "set bar";

	$foo->set_baz(-2);
	is $foo->baz, -7, "set baz";

	ok !eval { $foo->set_foo(10); 1 }, "setting foo failed";

	ok !eval { $foo->set_bar(8); 1 }, "setting bar failed";
}

class Doop {
	rw doop => 5,
		coerce => sub { $_[0] + 2 };

	rw deep => 0,
		constraint => sub { $_[0] == 100 },
		coerce => sub { $_[0] + 100 };

	rw bad => 9,
		constraint => sub { $_[0] > 9 };

	rw badder => -1,
		constraint => sub { $_[0] < 0 },
		coerce => sub { $_[0] + 1 };
}

my $doop = Doop->new(bad => 10, badder => -2);

is $doop->doop, 7, "doop default works";
is $doop->deep, 100, "deep default works";
is $doop->bad, 10, "bad works";
is $doop->badder, -1, "badder works";

ok !eval { Doop->new(deep => 1, bad => 10, badder => -2); 1 }, "deep constructed badly doesn't work";
ok !eval { Doop->new(badder => -2); 1 }, "bad default doesn't work";
ok !eval { Doop->new(bad => 10); 1 }, "badder default doesn't work";

done_testing;
