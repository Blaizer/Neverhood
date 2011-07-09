package Games::Neverhood::Video;
use strict;
use warnings;
use 5.01;
use autodie;
use File::Spec ();

use Games::Neverhood::Video::BitStream;
use Games::Neverhood::Video::Huffman::BigTree;

use constant no_store => qw/file next no_skip pos on_set on_unset/;

# file next no_skip pos on_set on_unset

sub new {
	my ($class, %arg) = @_;
	my $self = bless \%arg, ref $class || $class;
	# file
	# next
	# no_skip
	$self->{pos}[0] //= 0;
	$self->{pos}[1] //= 0;
	# on_set
	# on_unset

	open my $fh, File::Spec->catfile('share', 'video', @{$self->file});
	my $buf;

	# Header
	read $fh, $buf, 104;
	(@{$self->{Header}}{
		'Signature', # all SMK2
		'Width',
		'Height',
		'Frames',
		'FrameRate', # all negative
		'Flags',     # all 0
		'AudioSize', # all 0
		'TreesSize',
		'MMapSize',
		'MClrSize',
		'FullSize',
		'TypeSize',
		'AudioRate', # all 1 or 0 elements. have bit: 31=1, 30=1, 29=1 mostly but 0 for all m and one c, 28=0, 27-26=0, 25-24=0, 23-0=22050 but 11025 for all m
		'Dummy',     # all undef
	}) = unpack 'A4LLLlLA28LLLLLA28L', $buf;
	$self->{Header}{AudioSize} = [ unpack 'LLLLLLL', $self->{Header}{AudioSize} ];
	$self->{Header}{AudioRate} = [ unpack 'LLLLLLL', $self->{Header}{AudioRate} ];

	# FrameSizes
	read $fh, $buf, $self->{Header}{Frames} * 4;
	$self->{FrameSizes} = [ unpack 'L' x $self->{Header}{Frames}, $buf ];
	# no bit 0, no bit 1

	# FrameTypes
	read $fh, $buf, $self->{Header}{Frames};
	$self->{FrameTypes} = [ unpack 'C' x $self->{Header}{Frames}, $buf ];
	# all bit 0 on first FrameType some have bit 0 after, no bit 1 near the end..., no bits 2-7

	my $bit = Games::Neverhood::Video::BitStream->new($fh);

	$self->{HuffmanTrees}{MMap} = Games::Neverhood::Video::Huffman::BigTree->new($bit);
    $self->{HuffmanTrees}{MClr} = Games::Neverhood::Video::Huffman::BigTree->new($bit);
    $self->{HuffmanTrees}{Full} = Games::Neverhood::Video::Huffman::BigTree->new($bit);
    $self->{HuffmanTrees}{Type} = Games::Neverhood::Video::Huffman::BigTree->new($bit);

	$self->{bit} = $bit;
	
	$self;
}

use constant palmap => [
	0x00, 0x04, 0x08, 0x0C, 0x10, 0x14, 0x18, 0x1C,
	0x20, 0x24, 0x28, 0x2C, 0x30, 0x34, 0x38, 0x3C,
	0x41, 0x45, 0x49, 0x4D, 0x51, 0x55, 0x59, 0x5D,
	0x61, 0x65, 0x69, 0x6D, 0x71, 0x75, 0x79, 0x7D,
	0x82, 0x86, 0x8A, 0x8E, 0x92, 0x96, 0x9A, 0x9E,
	0xA2, 0xA6, 0xAA, 0xAE, 0xB2, 0xB6, 0xBA, 0xBE,
	0xC3, 0xC7, 0xCB, 0xCF, 0xD3, 0xD7, 0xDB, 0xDF,
	0xE3, 0xE7, 0xEB, 0xEF, 0xF3, 0xF7, 0xFB, 0xFF
];

sub next_frame {
	my ($self) = @_;
	my $bit = $self->{bit};
	
	my $frame_type = shift @{$self->{FrameTypes}};
	my $frame_size = shift @{$self->{FrameSizes}};
	
	if($frame_type & 1) { # palette
		# // System.Console.WriteLine("Updating palette");
		# var s = this.file.stream;
		my $old_pal = $self->{pal};
		$self->{pal} = [];
		my $size = $bit->read_8;
		$size = $size * 4 - 1;

		$frame_size -= $size + 1;
		my $sz = 0;
		# var pos = s.position + size;
		my $pal_index = 0;
		while($sz < 256) {
			my $t = $bit->read_8;
			if($t & 0x80) {
				# /* skip palette entries */
				$sz += ($t & 0x7F) + 1;
				for(my $i = 0; $i < ($t & 0x7F) + 1 && $sz < 256; $i++) {
					$self->{pal}[$pal_index++] = [0, 0, 0];
				}
			}
			elsif($t & 0x40 != 0) {
				# /* copy with offset */
				my $off = $bit->read_8;
				my $j = ($t & 0x3F) + 1;
				while($j-- != 0 && $sz < 256) {
				$self->{pal}[$pal_index++] = oldPallette[off];
				$sz++;
				$off++;
				}
			}
			else {
			# /* new entries */
			$self->{pal}[$pal_index++] = [palmap->[t], palmap->[$bit->read_8 & 0x3F], palmap->[$bit->read_8 & 0x3F]];
			$sz++;
			}
		}
		# s.seek(pos, "begin");
	}
	
	if($frame_type & 2 ) { # audio
	
	}
	
	# video
}

###############################################################################
### Accessors

sub file { $_[0]->{file} }
sub next { $_[0]->{next} }
sub no_skip { $_[0]->{no_skip} }
sub pos { $_[0]->{pos} }
# sub pos {
	# if(@_ > 1) { $_[0]->{pos} = $_[1]; return $_[0]; }
	# $_[0]->{pos};
# }
sub on_set {
	my $self = shift;
	$self->{on_set}->(@_) if $self->{on_set};
}
sub on_unset {
	my $self = shift;
	$self->{on_unset}->(@_) if $self->{on_unset};
}

for(<share/video/t>) {
	for(<$_/ID_40494081-FF.smk>) {
		s~share/video/~~;
		my $n = $_;
		my $game = Games::Neverhood::Video->new(
			file => [$_],
		);
		# print join " ", @{$game->{Header}}{qw/TreesSize MMapSize MClrSize FullSize TypeSize/};
	}
}

# my $game = Games::Neverhood::Video->new(
	# path => ['c', 'ID_018C0407-FF.smk'],
	# next => 'Scene::Shack';
	# no_skip => 1,
	# pos => [20, 40],
	# on_set => sub { $Game->no_skip(0) if $GG{did_this} },
	# on_unset => sub { $GG{did_this} = 1; },
# );

1;
