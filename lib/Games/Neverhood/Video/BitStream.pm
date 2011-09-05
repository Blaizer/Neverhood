use 5.01;
use strict;
use warnings;
package Games::Neverhood::Video::BitStream;

use constant CHUNK_SIZE => 512;

sub new {
	my ($class, $fh) = @_;
	bless {
		fh       => $fh,
		byte_off => CHUNK_SIZE,
		bit_off  => 8,
	}, ref $class || $class;
}

sub read_1 {
	my ($self) = @_;
	if($self->{bit_off} >= 8) {
		$self->{bit_off} = 0;
		$self->{byte_off}++;
		if($self->{byte_off} >= CHUNK_SIZE) {
			read $self->{fh}, $self->{buf}, CHUNK_SIZE;
			$self->{byte_off} = 0;
		}
		$self->{cur} = ord substr $self->{buf}, $self->{byte_off}, 1;
	}
	return $self->{cur} >> $self->{bit_off}++ & 1;
}

sub read_8 {
	my ($self) = @_;
	if($self->{bit_off} >= 8) {
		if(++$self->{byte_off} >= CHUNK_SIZE) {
			read $self->{fh}, $self->{buf}, CHUNK_SIZE;
			$self->{byte_off} = 0;
		}
		return ord substr $self->{buf}, $self->{byte_off}, 1;
	}
	my $ret = $self->{cur} >> $self->{bit_off};
	if(++$self->{byte_off} >= CHUNK_SIZE) {
		read $self->{fh}, $self->{buf}, CHUNK_SIZE;
		$self->{byte_off} = 0;
	}
	$self->{cur} = ord substr $self->{buf}, $self->{byte_off}, 1;
	return $ret | $self->{cur} << 8 - $self->{bit_off} & 0xFF;
}

sub read_16 {
	my ($self) = @_;
	my $ret;
	if($self->{bit_off} >= 8) {
		if(++$self->{byte_off} >= CHUNK_SIZE) {
			read $self->{fh}, $self->{buf}, CHUNK_SIZE;
			$self->{byte_off} = 0;
		}
		$ret = ord substr $self->{buf}, $self->{byte_off}, 1;
		if(++$self->{byte_off} >= CHUNK_SIZE) {
			read $self->{fh}, $self->{buf}, CHUNK_SIZE;
			$self->{byte_off} = 0;
		}
		return $ret | ord(substr $self->{buf}, $self->{byte_off}, 1) << 8;
	}
	$ret = $self->{cur} >> $self->{bit_off};
	if(++$self->{byte_off} >= CHUNK_SIZE) {
		read $self->{fh}, $self->{buf}, CHUNK_SIZE;
		$self->{byte_off} = 0;
	}
	$ret |= ord(substr $self->{buf}, $self->{byte_off}) << 8 - $self->{bit_off};
	if(++$self->{byte_off} >= CHUNK_SIZE) {
		read $self->{fh}, $self->{buf}, CHUNK_SIZE;
		$self->{byte_off} = 0;
	}
	$self->{cur} = ord substr $self->{buf}, $self->{byte_off}, 1;
	$ret | $self->{cur} << 16 - $self->{bit_off} & 0xFFFF;
}

sub reset {
	my ($self) = @_;
	$self->{byte_off} = -1;
	$self->{bit_off} = 8;
	
}

1;
