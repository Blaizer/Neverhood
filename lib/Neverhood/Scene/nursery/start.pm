class Neverhood::Scene::nursery::start {
extends Neverhood::Scene;

rw_ lever =>;
rw_ window =>;
rw_ button =>;
rw_ door =>;
rw_ hammer =>;

state $rect_list = [
	[ [301, 188, 382, 333], { window => 0 } ],
	[ [46, 303, 105, 418],  { lever => 0 } ],
	[ [452, 326, 491, 362], { button => 0 } ],
	[ [532, 221, 581, 433], { door => 0 } ],
	[ [150, 105, 531, 479], { walk => 0 } ],
	[ [46, 105, 149, 479],  { walk => 0 } ],
];

method first {
	$self->set_music("061880C6");
	$self->set_background("4086520E");
	$self->set_cursor("6520A400");
	$self->set_rect_list($rect_list);

	$self->add_klaymen;

	$self->add_sprite("809861A6", z => 950);
	$self->add_sprite("89C03848", z => 1100);
	my $door_cover = $self->add_sprite("2080A3A8", z => 1300);
	my $door_clip = [0, 0, $door_cover->x + $door_cover->w, 480];

	# $self->klaymen->set_clip_rect($door_clip);

	if (!$;->global->door_busted) {
		$self->add(door =>
			clip_rect => $door_clip,
		);
	}

	$self->add(button =>
		resource => "15288120",
		z => 100,
	);
	$self->add(lever =>);

	if (!$;->global->window_open) {
		my $window_cover = $self->add_sprite("8C066150", z => 200);
		$self->add(window =>
			clip_rect => $window_cover->draw_rect,
		);
	}

	$self->add(hammer =>);
}

method render {
	# hit rects
	Neverhood::App::set_render_color(255, 0, 0, 255);

	# main rect list
	Neverhood::App::set_render_color(0, 255, 0, 255);
	for (@{$self->rect_list}) {
		Neverhood::App::render_bounds($_->[0]);
	}

	# collision rects
	Neverhood::App::set_render_color(0, 0, 255, 255);
	for (@{$self->items}) {
		if ($_->isa("Neverhood::Sequence")) {
			Neverhood::App::render_rect($_->collision_rect);
		}
	}
}

class lever {
	extends Neverhood::Sequence;

	re resource => "04A98C36";
	re x => 150;
	re y => 433;
	re z => 1010;
	re flip => 1;
	# re stick_frame => 0;

	method first {
	}
}

class window {
	extends Neverhood::Sequence;

	re resource => "C68C2299";
	re x => 320;
	re y => 240;
	re z => 100;
	re stick_frame => 0;

	method first {
	}
}

class button {
	extends Neverhood::Sprite;

	re visible => 0;

	method first {
	}
}

class door {
	extends Neverhood::Sequence;

	re resource => "624C0498";
	re x => 726;
	re y => 440;
	re z => 800;
	re stick_frame => 0;

	method first {
	}
}

class hammer {
	extends Neverhood::Sequence;

	re resource => "022C90D4";
	re x => 547;
	re y => 206;
	re z => 900;
	# re -stick_frame => 0;

	method first {
	}
}

} 1;
