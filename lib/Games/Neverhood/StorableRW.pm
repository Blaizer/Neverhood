use 5.01;
use strict;
use warnings;
package Games::Neverhood::StorableRW;

use Storable ();

# overload this
use constant dont_store => [];

sub STORABLE_freeze {
	my ($self, $cloning) = @_;
	return if Storable::is_storing() or $cloning;
	
	# remove the keys in dont_store from the object, keeping them safe in a separate hash
	my %safe;
	for(@{$self->dont_store}) {
		$safe{$_} = delete $self->{$_} if exists $self->{$_};
	}
	
	# continue if we deleted anything
	return unless %safe;
	
	# perform freeze on the modified object
	my $freeze = Storable::freeze($self);
	
	# restore the object back to its original state
	while(my ($k, $v) = each %safe) { $self->{$k} = $v }
	
	return $freeze;
}

1;
