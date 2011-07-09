use 5.01;
use strict;
use warnings;
use Test::More;
use autodie;
use File::Spec;

use Games::Neverhood::Video::BitStream;
use Games::Neverhood::Video::Huffman::Tree;
can_ok('Games::Neverhood::Video::Huffman::Tree', qw/new decode/);

open my $fh, File::Spec->catfile('test', 'tree');
my $bit = Games::Neverhood::Video::BitStream->new($fh);

my $tree = Games::Neverhood::Video::Huffman::Tree->new($bit);
#      <--'0'- -'1'-->
#            ( )
#           /   \
#          /    ( )
#         /    /   \
#       ( )  (7)   (8)
#      /   \
#    ( )   (6)
#   /   \
# (3)   ( )
#      /   \
#    (4)   (5)

is($tree->decode($bit), 4, "decoded 4 first");
is($tree->decode($bit), 7, "decoded 7 second");
is($tree->decode($bit), 3, "decoded 3 third");
is($tree->decode($bit), 6, "decoded 6 fourth");
is($tree->decode($bit), 8, "decoded 8 fifth");
is($tree->decode($bit), 5, "decoded 5 sixth");

done_testing;
