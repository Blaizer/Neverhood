=head1 NAME

Neverhood::MoviePlayer - drawable object to play movies (smacker resources)

=cut

class Neverhood::MoviePlayer
{
	use SDL::Constants ':SDL::GFX';
	with 'Neverhood::Draw', 'Neverhood::Tick';

	ro key            => Str, required;
	ro is_double_size => Bool, default => 1;
	ro palette        => Palette;
	rw is_loopy       => Bool, default => 1;
	rw stopped        => Bool, default => 1;

	method cur_frame   () { $self->_resource->get_cur_frame }
	method frame_count () { $self->_resource->get_frame_count }

	pvt resource            => 'Neverhood::SmackerResource';
	pvt surface             => Surface;
	pvt double_size_surface => Surface;

	method BUILD {
		$self->_set_resource($;->resource_man->get_smacker($self->key.""));
		$self->_set_surface($self->_resource->get_surface);
		$self->set_fps($self->_resource->get_frame_rate);
	}

	method next_frame () {
		if (!$self->_resource->next_frame()) {
			if ($self->is_loopy) {
				$self->_resource->stop();
				$self->_resource->next_frame();
			}
			else {
				$self->set_stopped(1);
				return;
			}
		}

		my $surface = $self->_surface;
		if ($self->is_double_size) {
			$self->_set_double_size_surface(SDL::GFX::Rotozoom::surface($surface, 0, 2, SMOOTHING_OFF));
			$surface = $self->_double_size_surface;
			# remove the color key from it now because rotozoom makes 0,0,0 transparent for some reason
			Neverhood::SurfaceUtil::set_color_keying($surface, 0);
		}
		if ($self->palette) {
			Neverhood::SurfaceUtil::set_palette($surface, $self->palette);
		}
		$self->set_stopped(0);
		$self->invalidate();
	}

	method stop () {
		$self->_resource->stop();
		$self->ticker_stop();
		$self->set_stopped(1);
	}

	method handle_time (Num $time) {
		# go to the first frame on the first update
		if ($self->cur_frame == -1) {
			$self->next_frame();
		}
	}

	method handle_tick () {
		$self->next_frame();
	}

	method resync () {
		my $bytes_per_second = $self->_resource->audio_bytes_per_second;
		my $max_bytes_consumed = $self->_resource->max_audio_bytes_consumed;
		my $min_bytes_consumed = $max_bytes_consumed - $self->_resource->audio_bytes_buffer_size;

		my $seconds = $self->cur_frame * $self->_ticker_tick_time + $self->_ticker_time_remaining;
		my $bytes = $seconds * $bytes_per_second;

	}

	method draw () {
		my $surface = $self->is_double_size ? $self->_double_size_surface : $self->_surface;
		$self->draw_surface($surface, $self->x, $self->y);
	}
}
