use SDL;
use SDLx::Surface;
use SDL::GFX::Rotozoom;
use SDLx::App;

my $app = SDLx::App->new(dt => 0.2);
my $s = SDLx::Surface->load('./DATA/klaymen/idle.png');
my $rad = 0;

$app->add_move_handler(sub {
	my $zoom = cos $rad;
	$rad += 1 * $_[0];
	
	#these both work for me
	# my $s = SDL::GFX::Rotozoom::zoom_surface($s, $zoom, 1, 0);
	my $s = SDL::GFX::Rotozoom::surface_xy($s, 0, $zoom, 1, 0);
	
	#these don't even have a src argument... Wut?
	# my $s = SDL::GFX::Rotozoom::surface_size(width, height, angle, zoom);
	# my $s = SDL::GFX::Rotozoom::surface_size_xy(width, height, angle, zoomx, zoomy);
	# my $s = SDL::GFX::Rotozoom::zoom_surface_size(width, height, zoomx, zoomy);

	
	
	
	$app->draw_rect;
	$app->blit_by($s, undef, [200 - $s->w / 2, 0]);
	$app->flip;
});
$app->run;