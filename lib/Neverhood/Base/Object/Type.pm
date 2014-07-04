package Neverhood::Base::Object::Type;
use parent qw/Mouse::Meta::TypeConstraint/;

use Data::Dumper ();

sub new {
	my $class = shift;
	my %args = @_;

	$args{name} = "__ANON__" if !exists $args{name};

	if (exists $args{check}) {
		my $check = delete $args{check};
		$args{constraint} = sub {
			$check->(@_) || 1;
		}
	}

	my $self = bless \%args, $class;
	$self->compile_type_constraint;
	$self;
}

sub coerce {
	my $self = shift;
	goto $self->{coerce};
}

sub has_coercion {
	my $self = shift;
	$self->{coerce};
}

sub name {
	my $self = shift;
	$self->{name};
}

sub message {
	\&_message;
}
sub _message {
	my $message = Data::Dumper->Dump([@_], ["value"]);
	$message =~ s/^.*\K\n$//; # remove the trailing newline if it's only one line
	$message;
}

1;
