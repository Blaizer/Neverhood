use 5.01;
use strict;
use warnings;
use Test::More;
use autodie;
use File::Spec;

use Games::Neverhood::Video::BitStream;
can_ok('Games::Neverhood::Video::BitStream', qw/new read_1 read_8 read_16/);

open my $fh, File::Spec->catfile('test', 'bitstream');
my $bit = Games::Neverhood::Video::BitStream->new($fh);

# bits in test/bitstream
# 00000000 10101010 01010111 00000000 10110011 11111111 01010101 00000000

my @bits = split /\s*/, '00000000 01010101 11101010 00000000 11001101 11111111 10101010 00000000';
for(0..$#bits) {
	is($bit->read_1, $bits[$_], "read_1: bit $_ is $bits[$_]");
}
$bit->reset;

my @bytes = (0b00000000, 0b10101010, 0b01010111, 0b00000000, 0b10110011, 0b11111111, 0b01010101, 0b00000000);
for(0..$#bytes) {
	is($bit->read_8, $bytes[$_], "read_8: byte $_ is $bytes[$_]");
}
$bit->reset;

my @words = (0b1010101000000000, 0b0000000001010111, 0b1111111110110011, 0b0000000001010101);
for(0..$#words) {
	is($bit->read_16, $words[$_], "read_16: word $_ is $words[$_]");
}
$bit->reset;

$bit->read_1;
$bit->read_1;
is($bit->read_8, 0b10000000, "read_1,1,8 is 128");
is($bit->read_1, 0, "read_1 is then 0");
is($bit->read_1, 1, "read_1 is then 1");
is($bit->read_16, 0b0000010101111010, "read_16 is then 1402");
is($bit->read_1, 0, "read_1 is then 0");
is($bit->read_1, 0, "read_1 is then 0");
is($bit->read_8, 0b11001100, "read_8 is then 204");
is($bit->read_1, 0, "read_1 is then 0");
is($bit->read_16, 0b1010101111111111, "read_16 is then 44031");
is($bit->read_1, 0, "read_1 is then 0");
is($bit->read_8, 0b00000000, "read_8 is then 0");

close $fh;
undef $fh;
open $fh, File::Spec->catfile('test', 'tree');
$bit = Games::Neverhood::Video::BitStream->new($fh);

# 1, 1, 1, 1, 0, 3, 1, 0, 4, 0, 5, 0, 6, 1, 0, 7, 0, 8
is($bit->read_1, 1, "read_1 on tree is 1");
is($bit->read_1, 1, "read_1 on tree is then 1");
is($bit->read_1, 1, "read_1 on tree is then 1");
is($bit->read_1, 1, "read_1 on tree is then 1");
is($bit->read_1, 0, "read_1 on tree is then 0");
is($bit->read_8, 3, "read_8 on tree is then 3");
is($bit->read_1, 1, "read_1 on tree is then 1");
is($bit->read_1, 0, "read_1 on tree is then 0");
is($bit->read_8, 4, "read_8 on tree is then 4");
is($bit->read_1, 0, "read_1 on tree is then 0");
is($bit->read_8, 5, "read_8 on tree is then 5");
is($bit->read_1, 0, "read_1 on tree is then 0");
is($bit->read_8, 6, "read_8 on tree is then 6");
is($bit->read_1, 1, "read_1 on tree is then 1");
is($bit->read_1, 0, "read_1 on tree is then 0");
is($bit->read_8, 7, "read_8 on tree is then 7");
is($bit->read_1, 0, "read_1 on tree is then 0");
is($bit->read_8, 8, "read_8 on tree is then 8");

done_testing;
