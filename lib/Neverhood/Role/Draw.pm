=head1 NAME

Neverhood::Role::Draw - role that standardises drawing

=head1 DESCRIPTION

Also handles "invalidating" of rects on the screen to call $app->update() minimally.

There are 3 ways that drawable objects can be updated on the screen. The object will try to be updated by the below items, in order.

=over

1. You can call C<invalidate_all> to invalidate the entire screen. If you call it on an object, it will also C<invalidate> the object. This method is called whenever the scene changes, but you can also call it yourself.

2. Every time C<draw> is called on an object, the rect that is drawn is saved. If this rect is different to the previous rect that was drawn for the object, then both rects are updated on the screen.

3. You can call C<invalidate> on an object. This will update the object's draw rect even if it isn't different to the previous one. C<invalidate> should be called on an object when it changes, but its draw rect won't necessarily change (eg. when you mirror the sprite, change the draw clip, change its palette or when its visibility changes). C<check> is just a trigger that calls C<invalidate> when the value is different to the old value.

=back

Once C<draw> is called on an object, its C<invalidated> will be set to false.

=cut

role Neverhood::Role::Draw {
	requires 'draw';

	my $_invalidated_all;   # Bool
	my @_invalidated_rects; # ArrayRef[Surface]
	my $_screen_rect = SDL::Rect->new(0, 0, 640, 480);

	use constant is_visible => 1;

	rw name       => Str, default => '';
	rw visible    => Bool, default => 1, check;
	rw ['x', 'y'] => Int;
	rw app_clip   => Maybe[Rect];

	rw_ invalidated => Bool;
	pvt update_rect => Maybe[Rect];

	# done manually by anything that wants to invalidate the entire screen
	method invalidate_all () {
		$_invalidated_all = 1;
		$self->invalidate() if ref $self;
		@_invalidated_rects = ();
	}

	# done manually by a surface that wants to be invalidated
	method invalidate () {
		$self->set_invalidated(1);
	}

	# update rects on the app
	method update_screen () {
		if ($_invalidated_all) {
			SDL::Video::update_rect($;->app, 0, 0, 0, 0);
		}
		elsif (@_invalidated_rects) {
			SDL::Video::update_rects($;->app, @_invalidated_rects);
		}

		$_invalidated_all = 0;
		@_invalidated_rects = ();
	}

	around draw {
		my $update_rect = SDLx::Rect->new;
		my $old_update_rect = $self->_update_rect;
		$self->_set_update_rect($update_rect);

		# draw methods call Role::Draw::draw_* methods which modify $update_rect
		$self->$orig(@_) if $self->is_visible;

		if ($self->invalidated) {
			$self->_add_update_rect($old_update_rect);
			$self->_set_invalidated(0);
		}
	}

	method _add_update_rect (Maybe[Rect] $old_update_rect?) {
		return if $_invalidated_all;

		my $update_rect = $self->_update_rect;
		my @rects;
		if ($old_update_rect) {
			if ($update_rect->colliderect($old_update_rect)) {
				# if the rects collide, update the bigger rect that fits them both
				@rects = $update_rect->union($old_update_rect);
			}
			else {
				# if the rects don't collide, update both separately
				@rects = ($update_rect, $old_update_rect);
			}
		}
		else {
			@rects = $update_rect;
		}

		if (grep Neverhood::CUtil::rects_equal($_, $_screen_rect), @rects) {
			$self->invalidate_all;
			return;
		}
		push @_invalidated_rects, @rects;
	}

	# draw methods must call these methods to draw
	method draw_surface (Surface $surface, Int :$x, Int :$y, Int :$z, Maybe[Rect] :$clip)
	{
		$x //= $self->x;
		$y //= $self->y;
		$z //= 0;
		my ($w, $h) = $clip ? ($clip->w, $clip->h) : ($surface->w, $surface->h);
		my $update_rect = SDLx::Rect->new($x, $y, $w, $h);

		$update_rect->clip_ip($self->app_clip // $_screen_rect);

		SDL::Video::blit_surface($surface, $clip, $;->app, $update_rect);

		$self->_update_rect->union_ip($update_rect);
	}
	method draw_rect ($rect, $color) {
		$;->app->draw_rect($rect, $color);
		$self->_update_rect->union_ip($rect);
	}

	# called when drawables are added/removed from the scene
	method on_add () {
		$self->invalidate();
	}
	method on_remove () {
		$self->_add_update_rect() if $self->_update_rect;
		$self->_set_update_rect(undef);
	}
}
