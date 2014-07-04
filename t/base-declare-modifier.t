use Neverhood::Base;
use Test::More;

plan tests => 16;

role Neverhood::RoleTest1 {
	requires qw/asd/;

	rw str => '';

	before asd {
		Test::More::is $self->x, 4, "before 2";
		$self->set_x($self->x + 5);
		# x = 9
	}

	around asd {
		Test::More::is $self->x, 0, "around 2";
		$self->set_x($self->x * 50);
		# x = 0
		$self->$orig(@_);
	}

	after asd {
		Test::More::is $self->x, 4, "after 2";
		$self->set_x($self->x / 4);
		# x = 1
	}
}

role Neverhood::RoleTest2 {
	requires qw/asd/;

	rw int => 0;

	before asd ($this:) {
		Test::More::is $this->x, 9, "before 3";
		$this->set_x($this->x / 3);
		# x = 3
	}

	around asd ($this:) {
		Test::More::is $this->x, 0, "around 3";
		$this->set_x($this->x - 12);
		# x = -12
		$this->$orig(@_);
	}

	after asd ($this:) {
		Test::More::is $this->x, -36, "after 1";
		$this->set_x($this->x + 40);
		# x = 4
	}
}

my @pre_cleanup_stash;

class Neverhood::ClassTest1 {
	with Neverhood::RoleTest2;
	with Neverhood::RoleTest1;

	rw x => 2;

	method asd ($this:) {
		Test::More::is $this->x, -12, "method itself";
		$this->set_x($this->x * 3);
		# x = -36
	}

	before asd {
		Test::More::is $self->x, 2, "before 1";
		$self->set_x($self->x * 2);
		# x = 4
	}

	around asd {
		Test::More::is $self->x, 3, "around 1";
		$self->set_x($self->x - 3);
		# x = 0
		$self->$orig(@_);
	}

	after asd {
		Test::More::is $self->x, 1, "after 3";
		$self->set_x($self->x * 42);
		# x = 42
	}

	BEGIN { @pre_cleanup_stash = keys %Neverhood::ClassTest1:: }
	Test::More::ok !__PACKAGE__->meta->is_immutable, "not immutable yet";
}

my @post_cleanup_stash = keys %Neverhood::ClassTest1::;

my $self = Neverhood::ClassTest1->new;
ok $self->meta->is_immutable, "now we're immutable";

ok $self->does('Neverhood::RoleTest1'), "does RoleTest1";
ok $self->does('Neverhood::RoleTest2'), "does RoleTest2";

is $self->x, 2, "x starts at 2";
$self->asd;
is $self->x, 42, "x is now 42";

done_testing;

my %seen = map { ($_ => 1) } @post_cleanup_stash;
delete $seen{$_} for qw/x set_x int set_int str set_str asd/;
no strict;
@post_cleanup_stash = grep { *{"Neverhood::ClassTest1::$_"}{CODE} } keys %seen;
diag join " ", @post_cleanup_stash;
