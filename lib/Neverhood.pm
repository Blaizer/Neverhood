=head1 NAME

Neverhood - An engine for The Neverhood in Perl

=head1 SYNOPSIS

 use Neverhood;
 Neverhood->new_from_options->run;

=head1 AUTHOR

Blaise Roth <blaizer@cpan.org>

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2013 by Blaise Roth.

This is free software; you can redistribute and/or modify it under
the same terms as the Perl 5 programming language system itself.

See L<http://dev.perl.org/licenses/> for more information.

=cut

$Neverhood::VERSION = 0.23;

use Neverhood::Base;
use Neverhood::Options;
use Neverhood::ResourceMan;
use Neverhood::Global;
BEGIN {
	boot Neverhood::Stash;
	boot Neverhood::App;
	boot Neverhood::Archive;
	boot Neverhood::Sprite;
	boot Neverhood::Audio;
	boot Neverhood::Smacker;
	# boot Neverhood::Sounds;
}
use Neverhood::Drawable;
use Neverhood::SuperSprite;
use Neverhood::Sprite;
use Neverhood::Sequence;

use Neverhood::Scene;
use Neverhood::Scene::nursery::start;

class Neverhood {
with Neverhood::Options;
with Neverhood::ResourceMan;

rw_ global =>;
rw_ scene  =>;

method BUILD {
	# So we don't have to pass around the current scene object everywhere
	$; = $self;
	$self->set_global(Neverhood::Global->new);

	Neverhood::App::init();
}

method run () {
	Neverhood::App::run();

	undef $;;
}

method first () {
	$self->set_scene(Neverhood::Scene::nursery::start->new);
	$self->scene->first;
	$self->scene->Neverhood::Scene::first;
}

method next () {
	# $self->scene->next;
}

method on_space () {
	$self->scene->next;
	# $self->scene->on_space;
}

method on_escape () {
	Neverhood::App::stop();
}

method draw () {
	$self->scene->draw;
	Neverhood::Drawable::draw_all();
}
method render () {
	$self->scene->render;
}

} 1;
