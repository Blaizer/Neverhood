package Foo;
use Neverhood::Base;
use Test::More;

class Default {
	rw foo =>;
	rw bar => 2;
	rw baz => 5;
}

class NewDefault {
	extends Default;
	re foo => 7;
	re bar => 10;
}

class NewNewDefault {
	extends NewDefault;
	re foo => 77;
	re bar => 100;
	re baz => 55;
}

my $default = Default->new;
is $default->foo, undef, "foo has no default";
is $default->bar, 2, "bar has default";
is $default->baz, 5, "baz has default";

my $new_default = NewDefault->new;
is $new_default->foo, 7, "added default to foo";
is $new_default->bar, 10, "added default to bar";
is $new_default->baz, 5, "didn't add default to baz";

my $newnew_default = NewNewDefault->new;
is $newnew_default->foo, 77, "added new default to foo";
is $newnew_default->bar, 100, "added new default to bar";
is $newnew_default->baz, 55, "added new default to baz";

class More {
	rw b1 => builder => 'build1';
	rw b2 => builder => 'build2';
	rw b3 => 4;
	rw b4 => 6, builder => 'build4';

	method build1 { 11 }
	method build2 { 22 }
	method build4 { 44 }
}

class MoreMore {
	extends More;
	re b2 => builder => 'build22';
	re b3 => builder => 'build3';
	re b4 => builder => undef;

	method build1 { 999 }
	method build22 { 888 }
	method build3 { 777 }
}

class MoreMoreMore {
	extends MoreMore;
	re b1 => builder => 'build100';
	re b2 => builder => undef;
	re b3 => builder => undef;
	re b4 => builder => 'build400';

	method build100 { 1000 }
	method build400 { 4000 }
}

my $more = More->new;
is $more->b1, 11, "normal b1";
is $more->b2, 22, "normal b2";
is $more->b3, 4, "normal b3";
is $more->b4, 44, "normal b4";

my $moremore = MoreMore->new;
is $moremore->b1, 999, "more b1";
is $moremore->b2, 888, "more b2";
is $moremore->b3, 777, "more b3";
is $moremore->b4, 6, "more b4";

my $more3 = MoreMoreMore->new;
is $more3->b1, 1000, "more more b1";
is $more3->b2, undef, "more more b2";
is $more3->b3, 4, "more more b3";
is $more3->b4, 4000, "more more b4";

class Good {
	rw baz => 3, lazy => 1;
}
class Bad {
	extends Good;
	use Test::More;
	ok !eval { re baz => 4; 1 }, "can't re default of lazy attribute";
	ok !eval { re baz => builder => 4; 1 }, "can't re builder of lazy attribute";
}

class Bare {
	Mouse::has foo => is => 'bare';
	Mouse::has bar => is => 'bare', default => 17;

	method foo { $self->{foo} }
	method bar { $self->{bar} }
}
class BareGrill {
	extends Bare;
	re foo => 194;
	re bar => 195;
}

my $bare = Bare->new;
is $bare->foo, undef, "bare foo";
is $bare->bar, 17, "bare bar";

my $bare_grill = BareGrill->new;
is $bare_grill->foo, 194, "bare foo redefined";
is $bare_grill->bar, 195, "bare bar redefined";

done_testing;
