package App::Electric::Component;

use strict;
use warnings;

use Curses;
use Carp;

sub new {
	my $class = shift;
	ref($class) and croak "class name needed";
	my %opt = @_;
	my $self = {};
	bless $self, $class;
	$self->log("Component");
	defined( $self->window($opt{window}) ) or
		$self->{_log}->logcroak("window needed");
	$self;
}

sub process_event {
	my $self = shift;
	$self->{_log}->logcroak("$self needs to override method");
}

sub update {
	my $self = shift;
	$self->window()->refresh();
}

sub _check_process_event_opt {
	my $self = shift;
	my %opt = @_;
	unless(exists $opt{callback} && exists $opt{keypress}) {
		$self->log()->logcroak("proper options not passed");
	}
}

# 0/1 : (un)focus
sub focus {
	my $self = shift;
	if(@_) {
		my $old = $self->{_focus};
		$self->{_focus} = $_[0];
		return $old;
	} else {
		return $self->{_focus};
	}
}

sub window {
	my $self = shift;
	if(@_) {
		return $self->{_win} = $_[0];
	}
	$self->{_win} or $self->log()->logcroak("no window defined");
}

sub WINCH {
	my $self = shift;
	if(@_) {
		$self->{_WINCH} = $_[0];
	}
	return $self->{_WINCH};
}

# lines, columns
sub size {
	my $self = shift;
	if(@_) {
		$self->WINCH(1);
		$self->log()->info("Size: [@{$self->size()}] -> [@_]");
		$self->window()->resize($_[0], $_[1]);
	} else {
		my ($lines, $columns);
		$self->window()->getmaxyx($lines, $columns);
		return [$lines, $columns];
	}
}

sub lines {
	my $self = shift;
	return $self->size()->[0];
}

sub columns {
	my $self = shift;
	return $self->size()->[1];
}

# y, x
sub pos {
	my $self = shift;
	if(@_) {
		$self->window()->mvwin($_[0], $_[1]);
	} else {
		my ($y, $x);
		$self->window()->getbegyx($y, $x);
		return [$y, $x];
	}
}

sub log {
	my $self = shift;
	if(@_) {
		my $name = $_[0];
		$self->{_log} = Log::Log4perl::get_logger($name);
	}
	return $self->{_log};
}

1;
