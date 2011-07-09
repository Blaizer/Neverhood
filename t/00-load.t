use 5.01;
use strict;
use warnings;
no warnings 'once';

use Test::More;

use_ok(qw/
	Games::Neverhood
	Games::Neverhood::DualVar
	Games::Neverhood::Game
	Games::Neverhood::OrderedHash
		Games::Neverhood::OrderedHash::TiedArray
		Games::Neverhood::OrderedHash::TiedHash
	Games::Neverhood::Scene
		Games::Neverhood::Scene::Nursery::One
		Games::Neverhood::Scene::Nursery::One::OutWindow
	Games::Neverhood::Sprite
		Games::Neverhood::Sprite::Cursor
		Games::Neverhood::Sprite::Klaymen
	Games::Neverhood::Video
		Games::Neverhood::Video::BitStream
		Games::Neverhood::Video::HuffmanTree
/);

$Games::Neverhood::Fullscreen = 0;
eval { Games::Neverhood::init() };
ok( !$@, 'Games::Neverhood::init()' );

isnt( $Games::Neverhood::ShareDir, undef, 'Have a share dir' );

diag( "Testing Games::Neverhood $Games::Neverhood::VERSION, Perl $], $^X" );

done_testing;
