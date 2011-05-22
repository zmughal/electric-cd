package App::Electric::HManager;
use 5.010;
use parent ("App::Electric::Component");

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

# either initialize the components or update the size
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
		$self->{_component_init} = 1; # the components have be initialized once
	} else {
		$self->log()->info("Setting text component to [$text_lines, $columns]");
		$self->{_text_component}->size( $text_lines, $columns );
		$self->log()->info("Setting list component to [$list_lines, $columns]");
		$self->{_list_component}->size( $list_lines, $columns );
	}
}

sub process_event {
	my $self = shift;
	no warnings 'numeric';
	my %opt = @_;
	$self->log()->info("Processing event ", $opt{keypress}) unless $opt{keypress} == -1;
	$self->_check_process_event_opt(%opt);
	given($opt{keypress}) {
		when( unctrl($_) eq '^L') {
			$self->update_components();
		}
		when( -1 ) { return; }
		when(ord($_) == KEY_ESCAPE) { $opt{callback}->stop(); }
		when( KEY_RESIZE ) { $self->update_components(); }
		when( $_ eq "\t" ) {
			# toggle
			$self->toggle_focus();
		};
		default { 
			# delegate to focused component
			$self->focused_component()->process_event(%opt);
		}
	}
}

sub toggle_focus {
	my $self = shift;
	if($self->focused_component() == $self->{_text_component})
	{
		$self->focused_component($self->{_list_component})
	} else {
		$self->focused_component($self->{_text_component})
	}
	$self->focused_component()->update();
}

sub focus {
	my $self = shift;
	$self->focused_component()->focus(@_);
	$self->SUPER::focus(@_);
}

sub update {
	my $self = shift;
	if($self->WINCH()) {
		# reinit window sizes of components
		$self->log()->info("The size has changed to @{$self->size()}");
		$self->components_init();
		$self->update_components();
		$self->SUPER::update();
		$self->WINCH(0); # turn off flag for next time
	} else {
		$self->focused_component()->update();
		my %opt = @_;
		if(exists $opt{text}) {
			my $search = $opt{text};
			my $res;
			eval {
				$res = $self->{locate}->locate($search, { regexp => 1 } );
			};
			$self->{_list_component}->data($res) if $res;
			$self->update_components();
		}
		# TODO if the change is in the text component pipe the text
		# editor string  into the query and set the listcompent data
		# off that
		# or if the change is in the list component then perform the
		# action in the controller, e.g. selection
	}
}

sub update_components {
	my $self = shift;
	$self->{_list_component}->window()->touchwin();
	$self->{_list_component}->update();
	$self->{_text_component}->window()->touchwin();
	$self->{_text_component}->update();
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
