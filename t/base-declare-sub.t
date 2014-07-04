package Foo;
use Neverhood::Base;
use Test::More;

my $foo = func { "a" };
my $bar = func ($a, $b) { "$a $b" };

is $foo->(), "a", "func expression works";
is $bar->(1, 2), "1 2", "func expression with args works";

func simple { "b" }
func complex ($name, $message) { "Hi $name, $message" }

is simple(), "b", "func block works";
is complex("Fred", "sup?"), "Hi Fred, sup?", "func block with args works";

method foo { "$self yay" }
method bar ($a, $b) { "$self $a $b" }
method baz ($this:) { "Woah $this" }
method qux ($this: $c, $d) { "$c $d $this" }

is +Foo->foo, "Foo yay", "method block works";
is +Foo->bar(1, 2), "Foo 1 2", "method block with args works";
is +Foo->baz, "Woah Foo", "method block with invocant works";
is +Foo->qux(3, 4), "3 4 Foo", "method block with invocant and args works";

$foo = method { "$self!" };
$bar = method ($a, $b) { "$self=$a+$b?" };

is +Foo->$foo, "Foo!", "method expression works";
is +Foo->$bar(2,3), "Foo=2+3?", "method expression with args works";

my $moo = _around ($c) { "$orig $self $c" };
_around moo ($another) { "$orig-$self-$another" }

is $moo->(1, "self", 2), "1 self 2", "_around expression works";
is moo(3, "this", 4), "3-this-4", "_around block works";

is later(), "Woop", "block form happens at compile time";
func later { "Woop" }

done_testing;
