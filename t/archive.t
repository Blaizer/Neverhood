use Neverhood::Base;
use Test::More;
use File::Temp qw/tempfile/;

# creates a file with a string, returns the Neverhood::Archive of that file
sub archive {
	my ($buffer) = @_;
	my ($fh, $filename) = tempfile;
	binmode $fh;
	print {$fh} $buffer;
	return eval { Neverhood::Archive->new($filename) };
}

# testing every failure case of an archive

ok !archive("x" x 15), "Header not long enough";
ok !archive("x" x 16), "Magic incorrect";

my $magic = pack "L>", 0x40490002;

ok !archive($magic . "x" x 12, "id incorrect";

my $id = pack "S<", 7;

ok !archive($magic . $id . "x" x 10, "File size incorrect");

my $ext_data_size = pack "s", 0;
my $file_size = pack "l<", 16;
my $file_count = pack "l<", 178956970;

ok !archive($magic . $id . $ext_data_size . $file_size . $file_count, "File count too high, will overflow");

$file_count = pack "l<", 178956969;

ok !archive($magic . $id . $ext_data_size . $file_size . $file_count, "Header ok but keys too short");

$file_count = pack "l<", 2;
$file_size = pack "l<", 24;

ok archive($magic . $id . $ext_data_size . $file_size . $file_count . "x" x 8, "All ok without ext_data");

$ext_data_size = pack "s", 64;
$file_size = pack "l<", 16;
$file_count = pack "l<", 178956968;

ok !archive($magic . $id . $ext_data_size . $file_size . $file_count, "With ext_data file count too high, will overflow");

$file_count = pack "l<", 178956967;

ok !archive($magic . $id . $ext_data_size . $file_size . $file_count, "With ext_data header ok but keys too short");

$file_count = pack "l<", 178956968;
$ext_data_size = pack "s", 32;

ok !archive($magic . $id . $ext_data_size . $file_size . $file_count, "With lower ext_data header ok but keys too short");

# That's 10 tests, but there would be some more stuff about ext_data here

done_testing;
