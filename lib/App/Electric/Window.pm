package App::Electric::Window;

use strict;
use warnings;

use Curses;
use POSIX;
use List::Util qw/min max sum/;
use Log::Log4perl;
use Carp;
use IO::File;
use String::ShellQuote;
use File::Basename;

use Data::Dumper;

use App::Electric::HManager;

sub new {
	my $class = shift;
	ref($class) and croak "class name needed";
	my %opt = @_;
	my $self;
	$self->{_log} = Log::Log4perl::get_logger("Window");
	bless $self, $class;
	$self->init();
	$self->{_output}= new IO::File $opt{output}, "w";
	$self->{_log}->info("init");
	$self;
}

sub mainloop {
	my $self = shift;
	no warnings 'numeric';
	$self->{_log}->info("Starting mainloop");
	$self->{_running} = 1;
	my $key;
	do {
		# TODO: This may be better done using wgetch for ncurses state
		$key = getch;
		if($self->{_HACK_RESIZE}) {
			# I'm not exactly sure why I need to do this :-/ .
			# Internal state for ncurses?
			$self->{_focused_component}->process_event(
				callback => $self,
				keypress => KEY_RESIZE
			);
			$self->{_HACK_RESIZE} = 0;
		}
		$self->resized() if $key == KEY_RESIZE;
		$self->{_focused_component}->process_event(
			callback => $self,
			keypress => $key
		) unless ord($key) == -1;
	} while( defined($key) && $self->{_running} );
	cleanup(); # done
	if($self->{selected}) {
		my $fh = $self->{_output};
		print $fh "#!$ENV{SHELL}\n";
		my $dir = $self->get_dir($self->{selected});
		printf $fh "cd %s\n", shell_quote($dir);
		$self->{_output}->close;
	}
}

sub get_dir {
	my $self = shift;
	my $file = shift;
	if( -d $file && -r $file ) {
		return $file;
	} else {
		my ($name,$path,$suffix) = fileparse($file);
		return $path;
	}
}

sub update {
	my $self = shift;
	my %opt = @_;
	if(exists $opt{selected}) {
		$self->stop();
		$self->{selected} = $opt{selected};
		return;
	}
	$self->{_focused_component}->update(%opt);
}

sub init {
	my $self = shift;
	initscr;
	$SIG{__DIE__} = \&cleanup;
	$SIG{INT} = sub { cleanup(); exit(0); };
	noecho;
	cbreak;
	keypad(1);
	nodelay(1);
	#$self->_init_win();

	my ($maxy, $maxx);
	getmaxyx($maxy, $maxx);
	my $window = newwin($maxy, $maxx, 0, 0);

	my $hmanager = App::Electric::HManager->new( window => $window, );
	$self->{_log}->info("Size: @{$hmanager->size()}");
	$self->{_log}->info("Pos: @{$hmanager->pos()}");
	$self->{_focused_component} = $hmanager;
}

sub resized {
	my $self = shift;
	my ($ny, $nx);
	stdscr()->getmaxyx($ny, $nx);
	$self->{_log}->info("SIGWINCH: The size has changed to [$ny, $nx]");
	$self->{_focused_component}->size($ny,$nx);
	$self->update();
	$self->{_HACK_RESIZE} = 1;	# see mainloop()
}

sub stop {
	my $self = shift;
	$self->{_log}->info("Stopping");
	$self->{_running} = 0;
}

sub cleanup {
	clear;
	refresh;
	endwin;
}

1;
