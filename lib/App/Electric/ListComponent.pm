package App::Electric::ListComponent;
use base ("App::Electric::Component");

use strict;
use warnings;

use 5.010;
use Curses;
use Carp;
use List::Util qw/min max/;
use Data::Dumper;

sub new {
	my $class = shift;
	ref($class) and croak "class name needed";
	my %opt = @_;
	my $self = $class->SUPER::new(%opt);
	$self->data($opt{data} // []);
	$self->log("ListComponent");
	$self->{_old_scroll_pos} = -1;
	$self->{_scroll_pos} = 0;
	$self;
}

sub process_event {
	my $self = shift;
	# TODO
	my %opt = @_;
	$self->process_key($opt{keypress});
	my %callback_opt;
	$callback_opt{selected} = $self->selected() if exists $self->{_selected};
	$opt{callback}->update(%callback_opt);
}

sub process_key {
	my $self = shift;
	my $keypress = shift;
	given($keypress) {
		when( ord($_) == 10 ) {
			$self->{_selected} = 1;
		}
		when ( $_ !~ /\d{2,}/ ) {
			my $char = unctrl($_);
			given($char) {
				when('j') {
					$self->selection_down();
				}
				when('k') {
					$self->selection_up();
				}
			}
		}
		when( KEY_PPAGE ) {
			$self->scroll_up();
		}
		when( KEY_NPAGE ) {
			$self->scroll_down();
		}
		when( KEY_HOME ) {
			$self->home(1);
		}
		when( KEY_END ) {
			$self->end(1);
		}
		when( KEY_UP ) {
			$self->selection_up();
		}
		when( KEY_DOWN ) {
			$self->selection_down();
		}
	}
	$self->log()->info(Dumper($self->selected()));
}

sub data {
	my $self = shift;
	if(@_) {
		if( ref($_[0]) eq "ARRAY" ) {
			$self->{_data} = $_[0];
		} else {
			$self->{_data} = \@_;
		}
		$self->home(1);
	} else {
		return $self->{_data};
	}
}

sub home {
	my $self = shift;
	$self->{_log}->info("Going to home");
	if(@_) {
		$self->{_scroll_pos} = 0;
		$self->{_data_pos} = 0;
	} else {
		$self->{_data_pos} == 0;
	}
}

sub end {
	my $self = shift;
	my @data = @{$self->data()};
	$self->{_log}->info("Going to end");
	if(@_) {
		$self->{_scroll_pos} = max( 0, @data - $self->lines());
		$self->{_data_pos} = $#data;
	} else {
		$self->{_data_pos} == $#data;
	}
}

sub scroll_down {
	my $self = shift;
	my @data = @{$self->data()};
	$self->{_scroll_pos} = min($#data,
		$self->{_scroll_pos} + $self->lines() );
	my $dp =  $self->{_data_pos};
	$self->{_data_pos} = $self->{_scroll_pos}
		unless($dp >= $self->{_scroll_pos} &&
			$dp < $self->{_scroll_pos} + $self->lines());
}

sub scroll_up {
	my $self = shift;
	my @data = @{$self->data()};
	$self->{_scroll_pos} = max(0,
		$self->{_scroll_pos} - $self->lines());
	my $dp =  $self->{_data_pos};
	$self->{_data_pos} = $self->{_scroll_pos} + $self->lines() - 1
		unless($dp >= $self->{_scroll_pos} &&
			$dp < $self->{_scroll_pos} + $self->lines());
}

sub selection_down {
	my $self = shift;
	my @data = @{$self->data()};
	$self->{_data_pos} = ($self->{_data_pos} + 1) % @data;
	return $self->scroll_down() if($self->{_data_pos} >=
			$self->{_scroll_pos} + $self->lines());
	return $self->home() if($self->{_data_pos} == 0);
}

sub selection_up {
	my $self = shift;
	my @data = @{$self->data()};
	$self->{_data_pos} = (@data + $self->{_data_pos} - 1) % @data;
	return $self->scroll_up() if($self->{_data_pos} <
		$self->{_scroll_pos});
	return $self->end() if($self->{_data_pos} == $#data);
}

sub selected {
	my $self = shift;
	return $self->data()->[$self->{_data_pos}];
}

sub update {
	my $self = shift;
	#if($self->WINCH() || $self->{_old_scroll_pos} != $self->{_scroll_pos}) {
		# redraw
		my @data = @{$self->data()};
		$self->window()->clear();
		for my $cur (0..$self->lines()-1) {
			my $data_pos = $self->{_scroll_pos} + $cur;
			$self->log()->logcroak("Corruption: $data_pos is outside range") if ($data_pos < 0);
			$self->window()->move($cur, 0);
			$self->window()->clrtoeol();
			my $left_column = " ";
			$left_column = ">" if $data_pos == $self->{_data_pos};
			$self->window()->addstr($left_column.($data[$data_pos] // "~"));
		}
		$self->SUPER::update();
	#}
	# highlight current selection _data_pos
	# TODO: get this to work
	my $cur_line = $self->{_data_pos} - $self->{_scroll_pos};
	$self->window()->chgat($cur_line, 0, -1, A_BOLD , 1, 0);
	$self->WINCH(0);
	$self->{_old_scroll_pos} = $self->{_scroll_pos};
}

1;
