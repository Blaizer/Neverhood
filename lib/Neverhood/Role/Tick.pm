=head1 NAME

Neverhood::Role::Tick - role that ticks

=cut

role Neverhood::Role::Tick {
	pvt ticker_tick_time      => Num, trigger { $self->_set_ticker_remaining_time(0) };
	pvt ticker_remaining_time => Num;

	requires 'handle_time', 'handle_tick';

	after handle_time (Num $time) {
		$time += $self->_ticker_remaining_time;

		my $tick_time = $self->_ticker_tick_time;
		if ($time >= $tick_time) {
			$time -= $tick_time;
			$self->_set_ticker_remaining_time($time);
			$self->handle_tick();
			$self->handle_time(0);
		}
		else {
			$self->_set_ticker_remaining_time($time);
			$self->resync();
		}
	}

	method resync () {}

	method ticker_stop () {
		$self->_set_ticker_remaining_time(0);
	}

	method fps () {
		1 / $self->_ticker_tick_time;
	}
	method set_fps (Num $fps) {
		$self->_set_ticker_tick_time(1 / $fps);
	}
}
