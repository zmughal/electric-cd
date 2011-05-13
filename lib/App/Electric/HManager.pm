package App::Electric::HManager;
use base ("App::Electric::Component");
use 5.010;

use strict;
use warnings;

use Curses;
use App::Electric::EditingComponent;
use App::Electric::ListComponent;
use Carp;
use Data::Dumper;

use File::Locate::Harder;

use constant KEY_ESCAPE => 27;

sub new {
	my $class = shift;
	ref($class) and croak "class name needed";
	my %opt = @_;
	my $self = $class->SUPER::new(%opt);
	$self->log("HManager");
	$self->components_init();
	$self->focused_component($self->{_text_component});

	$self->{locate} = File::Locate::Harder->new();

	$self;
}

sub components_init {
	my $self = shift;
	my ($lines, $columns) = @{$self->size()};
	my $text_lines = 1;
	my $list_lines = $lines-$text_lines;

	unless($self->{_component_init}) {
		my $text_window = derwin( $self->window(), $text_lines, $columns, 0, 0);
		my $list_window = derwin( $self->window(), $list_lines, $columns, $text_lines, 0);
		$self->{_text_component} = App::Electric::EditingComponent->new( window => $text_window );
		$self->{_list_component} = App::Electric::ListComponent->new( window => $list_window );
	} else {
		$self->{_text_component}->size( $text_lines, $columns );
		$self->{_list_component}->size( $list_lines, $columns );
	}
}

sub process_event {
	my $self = shift;
	my %opt = @_;
	$self->log()->info("Processing event ", $opt{keypress});
	$self->_check_process_event_opt(%opt);
	given($opt{keypress}) {
		when(ord($_) == KEY_ESCAPE) { $opt{callback}->stop(); }
		when( $_ eq "\t" ) {
			# toggle
			if($self->focused_component() == $self->{_text_component})
			{
				$self->focused_component($self->{_list_component})
			} else {
				$self->focused_component($self->{_text_component})
			}
		};
		default { 
			# delegate to focused component
			$self->focused_component()->process_event(%opt);
		}
	}
}

sub focus {
	my $self = shift;
	$self->focused_component($self);
	$self->SUPER::focus(1);
}

sub update {
	my $self = shift;
	if($self->WINCH()) {
		# reinit window sizes of components
		$self->components_init();
		$self->{_text_component}->update();
		$self->{_list_component}->update();
		$self->WINCH(0); # turn off flag for next time
	} else {
		$self->focused_component()->update();
		my %opt = @_;
		if(exists $opt{text}) {
			my $search = $opt{text};
			my $res = $self->{locate}->locate($search, { regexp => 1 } );
			$self->{_list_component}->data($res);
			$self->{_list_component}->update();
			$self->{_text_component}->update();
		}
		# TODO if the change is in the text component pipe the text
		# editor string  into the query and set the listcompent data
		# off that
		# or if the change is in the list component then perform the
		# action in the controller, e.g. selection
	}
}

sub focused_component {
	my $self = shift;
	if(@_) {
		my $component = shift;
		if( $self->{_focused_component} &&
				$self->{_focused_component} != $component) {
			$self->{_focused_component}->focus(0)
		}
		$component->focus(1);
		return $self->{_focused_component} = $component;
	} else {
		return $self->{_focused_component};
	}
}

1;
