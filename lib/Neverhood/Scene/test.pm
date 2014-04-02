class Neverhood::Scene::Test extends Neverhood::Scene {
	rw button => 'Neverhood::Sprite';

	method setup (SceneName $prev_scene) {
		$self->set_background(x*4086520E);

		# #lever
		# $self->add_sprite(x*809861A6);

		# #hammer
		# $self->add_sprite(x*89C03848);

		# #window
		# $self->add_sprite(x*8C066150);

		# $self->add_sprite('button', x*15288120);

		# $self->add_sprite(x*2080A3A8);
	}
}
