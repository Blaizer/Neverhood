# a convenience class to provide a load and draw_xy method for SDL::Surface

use 5.01;
use strict;
use warnings;
package Games::Neverhood::Surface;

use SDL;
use parent 'SDL::Surface';
use SDL::Image;
use SDL::Video;
use SDL::Rect;

use File::Spec ();
use Carp ();

use Games::Neverhood qw/$ShareDir/;

sub new {
	my ($class, $file, $frame) = @_;
	
	if(-d File::Spec->catdir($ShareDir, $file)) {
		$file = File::Spec->catfile($ShareDir, $file, $frame);
	}
	else {
		$file = File::Spec->catfile($ShareDir, $file);
	}
	$file .= '.png';
	
	my $surface = SDL::Image::load($file)
		or Carp::confess("Could not load image '$file': " . SDL::get_error);
	
	bless $surface, ref $class || $class;
}

sub draw_xy {
	my ($self, $x, $y) = @_;
	SDL::Video::blit_surface(
		$self,
		SDL::Rect->new(0, 0, $self->w, $self->h),
		SDL::Rect->new($x, $y, 0, 0)
	);
}

1;
