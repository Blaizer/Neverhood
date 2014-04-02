use Neverhood::Base;
use Test::More;

class Neverhood::HasTest {
	rw  read_write  =>;
	ro  read_only   =>;
	rw_ read_write_ =>;
	rw_ _private    =>;
	rw  _private_rw =>;
	ro  _private_ro =>;
}

my $test = Neverhood::HasTest->new(
	read_write => 2,
	read_only  => 3,
	private_ro => 4,
	private_rw => 5,
);

is $test->read_write,  2, "read_write arg";
is $test->read_only,   3, "read_only arg";
is $test->_private_ro, 4, "private_ro arg";
is $test->_private_rw, 5, "private_rw arg";

$test->set_read_write (10);
$test->set_read_write_(11);
$test->_set_private   (12);
$test->_set_private_rw(13);

is $test->read_write,  10, "set and get read_write";
is $test->read_write_, 11, "set and get read_write_";
is $test->_private,    12, "set and get private";
is $test->_private_rw, 13, "set and get private_rw";

ok !eval { $test->set_read_only  (20); 1 }, "set read_only illegal";
ok !eval { $test->_set_private_ro(20); 1 }, "set private_ro illegal";

ok !eval { Neverhood::HasTest->new; 1 }, "both read_only required";
ok !eval { Neverhood::HasTest->new(read_only  => 13); 1 }, "private_ro is required";
ok !eval { Neverhood::HasTest->new(private_ro => 15); 1 }, "read_only is required";
ok  eval { Neverhood::HasTest->new(read_only => 11, private_ro => 18); 1 }, "works with required";

ok !eval { $test->_read_write;  1 }, "illegal get read_write";
ok !eval { $test->_read_write_; 1 }, "illegal get read_write_";
ok !eval { $test->_read_only;   1 }, "illegal get read_only";
ok !eval { $test->private;      1 }, "illegal get private";
ok !eval { $test->private_ro;   1 }, "illegal get private_ro";
ok !eval { $test->private_rw;   1 }, "illegal get private_rw";

ok !eval { $test->_set_read_write (30); 1 }, "illegal set read_write";
ok !eval { $test->_set_read_write_(30); 1 }, "illegal set read_write_";
ok !eval { $test->_set_read_only  (30); 1 }, "illegal set read_only";
ok !eval { $test->set_private     (30); 1 }, "illegal set private";
ok !eval { $test->set_private_rw  (30); 1 }, "illegal set private_rw";
ok !eval { $test->set_private_ro  (30); 1 }, "illegal set private_ro";

$test = Neverhood::HasTest->new(read_write_ => 7, read_only => 0, private_ro => 0);
is $test->read_write_, undef, "read_write_ arg does nothing";

$test = Neverhood::HasTest->new(private => 6, _private => 2, read_only => 0, private_ro => 0);
is $test->_private, undef, "private arg does nothing";

class Neverhood::DefaultTest {
	rw one   => default => 50;
	rw two   => 51;
	rw three => lazy => 1, default => 52;
	rw four  => 53, lazy => 1;
}

$test = Neverhood::DefaultTest->new;
is $test->one,   50, "default one";
is $test->two,   51, "default two";
is $test->three, 52, "default three";
is $test->four,  53, "default four";

class Neverhood::RequiredTest {
	rw required_rw => required => 1;
}
class Neverhood::RequiredPvtTest {
	rw _required_pvt => required => 1;
}

$test = Neverhood::RequiredTest->new(required_rw => 50);
is $test->required_rw, 50, "required rw";
ok !eval { Neverhood::RequiredTest->new; 1 }, "illegal required rw";

$test = Neverhood::RequiredPvtTest->new(required_pvt => 51);
is $test->_required_pvt, 51, "required pvt";
ok !eval { Neverhood::RequiredPvtTest->new; 1 }, "illegal required pvt";

# class Neverhood::TriggerTest {
# 	rw single => 0, trigger;
# 	rw ['multi1','multi2'], trigger;
# 	rw explicit => trigger { $self->set_e([$new, $old]) };

# 	rw ['s', 'm', 'n', 'e'] => sub { [] };

# 	trigger single { $self->set_s([$new, $old]) }
# 	trigger multi1 { $self->set_m([$new, $old]) }
# 	trigger multi2 { $self->set_n([$new, $old]) }
# }

# $test = Neverhood::TriggerTest->new;

# is_deeply $test->s, [], "not triggered single";
# is_deeply $test->m, [], "not triggered multi1";
# is_deeply $test->n, [], "not triggered multi2";
# is_deeply $test->e, [], "not triggered explicit";

# $test->set_single(60);
# is_deeply $test->s, [60, undef], "triggered single";
# $test->set_multi1(61);
# is_deeply $test->m, [61, undef], "triggered multi1";
# $test->set_multi2(62);
# is_deeply $test->n, [62, undef], "triggered multi2";
# $test->set_explicit(63);
# is_deeply $test->e, [63, undef], "triggered explicit";
# $test->set_single(64);
# is_deeply $test->s, [64, 60], "triggered single again";
# $test->set_multi1(65);
# is_deeply $test->m, [65, 61], "triggered multi1 again";
# $test->set_multi2(66);
# is_deeply $test->n, [66, 62], "triggered multi2 again";
# $test->set_explicit(67);
# is_deeply $test->e, [67, 63], "triggered explicit again";

done_testing;
