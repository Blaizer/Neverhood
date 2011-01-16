use strict;
use warnings;

use SDL;
use SDLx::App;
use SDL::Image;
use SDL::GFX::Rotozoom;
use SDL::Video;
use SDL::Rect;

my $App = SDLx::App->new(w => 640, h => 480, dt => 1/15);
my $Surface;
$App->add_move_handler(sub {
	$_ += $_[0];
	undef $Surface if int $_ > int $_ - $_[0];
});
$App->add_show_handler(sub {
	if(!defined $Surface) {
		my $name = 'Untitled_' . int($_) . '.png';
		$Surface = SDL::GFX::Rotozoom::surface(SDL::Image::load($name), 0, 2, 0);
	}
	SDL::Video::blit_surface(
		$Surface,
		SDL::Rect->new(0, 0, 640, 480),
		$App,
		SDL::Rect->new(0, 0, 0, 0)
	);
	SDL::Video::flip($App);
});
$App->run;
