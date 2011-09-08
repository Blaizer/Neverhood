use 5.01;
use strict;
use warnings;
package Games::Neverhood::Video::Huffman::BigTree;

use Games::Neverhood::Video::BitStream;
use Games::Neverhood::Video::Huffman::Tree;

sub new {
	my ($class, $bit) = @_;
	my $self = bless {}, ref $class || $class;

	return $self unless $bit->read_1;

	$self->{low_byte_tree}  = Games::Neverhood::Video::Huffman::Tree->new($bit);
	$self->{high_byte_tree} = Games::Neverhood::Video::Huffman::Tree->new($bit);

	$self->{marker_1} = $bit->read_16;
	$self->{marker_2} = $bit->read_16;
	$self->{marker_3} = $bit->read_16;

	$self->{marker_1_node} = [];
	$self->{marker_2_node} = [];
	$self->{marker_3_node} = [];

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
		my $leaf = $self->{low_byte_tree}->decode($bit) | $self->{high_byte_tree}->decode($bit) << 8;
		if($leaf == $self->{marker_1}) {
			$self->{marker_1_node} = $node;
			$leaf = 0;
		}
		if($leaf == $self->{marker_2}) {
			$self->{marker_2_node} = $node;
			$leaf = 0;
		}
		if($leaf == $self->{marker_3}) {
			$self->{marker_3_node} = $node;
			$leaf = 0;
		}
		$node->[0] = $leaf;
		return;
	}
	$self->build_tree_recurse($bit, $node->[1] = []);
}

sub decode {
	my ($self, $bit) = @_;
	my $node = $self->{tree};
	unless($node) {
		# warn 'trying to read from nonononono bigtree';
		return 0;
	}
	while(@$node > 1) {
		$node = $node->[$bit->read_1];
	}
	my $val = $node->[0];
	if($val != $self->{marker_1}) {
		$self->{marker_3} = $self->{marker_2};
		$self->{marker_2} = $self->{marker_1};
		$self->{marker_1} = $val;

		$self->{marker_3_node}[0] = $self->{marker_2_node}->[0];
		$self->{marker_2_node}[0] = $self->{marker_1_node}->[0];
		$self->{marker_1_node}[0] = $val;
	}
	return $val;
}

sub reset {
	my ($self) = @_;
	$self->{marker_1} = 0;
	$self->{marker_2} = 0;
	$self->{marker_3} = 0;

	$self->{marker_1_node}[0] = 0;
	$self->{marker_1_node}[1] = 0;
	$self->{marker_1_node}[2] = 0;
}

1;
