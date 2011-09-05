use 5.01;
use strict;
use warnings;
package Games::Neverhood::Video::Huffman::Tree;

use Games::Neverhood::Video::BitStream;

sub new {
	my ($class, $bit) = @_;
	my $self = bless {}, ref $class || $class;

	# warn ('skipping tree'),
	return $self unless $bit->read_1;

	$self->build_tree_recurse($bit, $self->{tree} = []);
	
	$bit->read_1;

	$self;
}

sub build_tree_recurse {
	my ($self, $bit, $node) = @_;
	if($bit->read_1) {
		$self->build_tree_recurse($bit, $node->[0] = []);
	}
	else {
		warn 'what going on' if @$node;
		$node->[0] = $bit->read_8;
		return;
	}
	$self->build_tree_recurse($bit, $node->[1] = []);
}

sub decode {
	my ($self, $bit) = @_;
	my $node = $self->{tree};
	unless($node) {
		# warn 'trying to read from nonononono tree';
		return 0;
	}
	while(@$node > 1) {
		$node = $node->[$bit->read_1];
	}
	return $node->[0];
}

1;