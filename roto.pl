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
	my $s = SDL::GFX::Rotozoom::zoom_surface( $s, $zoom, 1, 0);
	$app->draw_rect;
	$app->blit_by($s, undef, [200 - $s->w / 2, 0]);
	$app->flip;
});
$app->run;