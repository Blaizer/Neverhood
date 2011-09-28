# a convenience class to provide some Neverhood specific methods for SDL::Surface

use 5.01;
use strict;
use warnings;
package Games::Neverhood::Surface;

use SDL;
use parent 'SDL::Surface';
use SDL::Image;
use SDL::Video;
use SDL::Rect;
use SDL::PixelFormat;
use SDL::Palette;
use SDL::GFX::Rotozoom;

use File::Spec ();
use Carp ();

use Games::Neverhood qw/$ShareDir/;

sub new {
	my ($class, $dir, $file, $frame) = @_;
	
	if(-d File::Spec->catdir($ShareDir, $dir, $file)) {
		$file = File::Spec->catfile($ShareDir, $dir, $file, $frame);
	}
	else {
		$file = File::Spec->catfile($ShareDir, $dir, $file);
	}
	$file .= '.png';
	
	my $surface = SDL::Image::load($file)
		or Carp::confess("Could not load image '$file': " . SDL::get_error);
	
	bless $surface, ref $class || $class;
}

sub blit {
	my ($self, $pos, $clip) = @_;
	SDL::Video::blit_surface(
		$self,
		SDL::Rect->new($clip ? @$clip : (0, 0, $self->w, $self->h)),
		$;->app,
		SDL::Rect->new(@$pos, 0, 0)
	);
}

sub do_alpha {
	my ($self) = @_;
	SDL::Video::set_color_key(
		$self,
		SDL_SRCCOLORKEY | SDL_RLEACCEL,
		$self->format->palette->color_index(0)
	);
}

sub do_mirror {
	my ($self) = @_;
	# surface_xy( surface, angle, zoom_x, zoom_y, smooth )
	$self = bless SDL::GFX::Rotozoom::surface_xy($self, 0, -1, 1, 0), ref $self;
}

1;
