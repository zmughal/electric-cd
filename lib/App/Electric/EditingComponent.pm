package App::Electric::EditingComponent;
use 5.010;
use parent ("App::Electric::Component");

use strict;
use warnings;

use Curses;
use Carp;
use Data::Dumper;
use List::Util qw/min max/;

use constant PROMPT => "> ";
use constant END_POS => -1;

sub new {
	my $class = shift;
	ref($class) and croak "class name needed";
	my $self = $class->SUPER::new(@_);
	my %opt = @_;
	$self->{_old_scroll_pos} = -1;
	$self->text($opt{text} // "");
	$self->log("EditingComponent");
	$self->window()->move(0,0);
	$self;
}

sub text {
	my $self = shift;
	if(@_) {
		$self->{_text} = $_[0];
		$self->end();
	}
	return $self->{_text};
}

sub home {
	my $self = shift;
	$self->{_data_pos} = 0;
	$self->{_scroll_pos} = 0;
}

sub end {
	my $self = shift;
	my $columns = $self->canvas_columns();
	my $length = length($self->text());
	$self->{_data_pos} = END_POS;
	$self->{_scroll_pos} = max(0,
		$length-$columns+1
	);
}

sub canvas_columns {
	my $self = shift;
	return $self->columns();
}

sub right {
	my $self = shift;
	if($self->{_data_pos} != END_POS) {
		my $columns = $self->canvas_columns();
		my $text = $self->text();
		$self->{_data_pos}++;
		$self->{_data_pos} = END_POS if($self->{_data_pos} >= length($text));
		my $cur_col = $self->{_data_pos} - $self->{_scroll_pos};
		if($cur_col > $columns - 1) {
			$self->{_scroll_pos} = min(
				$self->{_scroll_pos}+$columns,
				length($text) - 1
			);
		}
	}
}

sub left {
	my $self = shift;
	if($self->{_data_pos} != 0) {
		my $columns = $self->canvas_columns();
		my $text = $self->text();
		my $oneless = $self->{_data_pos}-1;
		$oneless = length($text)-1 if($self->{_data_pos} == END_POS);
		$self->{_data_pos} = max(0, $oneless);
		my $cur_col = $self->{_data_pos} - $self->{_scroll_pos};
		if($cur_col < 0) {
			$self->{_scroll_pos} = max(
				$self->{_scroll_pos}-$columns,
				0
			);
		}
	}
}

sub delete_char_right {
	my $self = shift;
	unless($self->{_data_pos} == END_POS) {
		substr($self->{_text}, $self->{_data_pos}, 1) = "";
		$self->{_old_scroll_pos} = -1;
	}
}

sub delete_char_left {
	my $self = shift;
	# NOTE: Use of delch here may be optimal
	# $self->window()->delch();
	my $text = $self->text();
	my $pos = $self->{_data_pos} == END_POS ? length($text) : $self->{_data_pos};
	unless($pos == 0) {
		my $del = substr $self->{_text}, $pos-1, 1;
		substr($self->{_text}, $pos-1, 1) = "";
		$self->{_data_pos}-- unless $self->{_data_pos} == END_POS;
		$self->{_old_scroll_pos} = -1;
		return $del
	}
	return 0;
}

sub delete_to_eol {
	my $self = shift;
	substr($self->{_text}, $self->{_data_pos})= "";
	$self->{_data_pos} = END_POS;
	$self->{_old_scroll_pos} = -1;
}

sub delete_to_bol {
	my $self = shift;
	unless($self->{_data_pos} == END_POS) {
		substr($self->{_text}, 0, $self->{_data_pos}) = "";
		$self->home();
	} else {
		$self->text("");
	}
}

sub addchar {
	my $self = shift;
	my $char = shift;
	# NOTE: Use of
	# $self->window()->addch($char);
	# may be more optimal
	my $pos = $self->{_data_pos} == END_POS ? length($self->text()) : $self->{_data_pos};
	substr($self->{_text}, $pos, 0) = $char;
	unless($self->{_data_pos} == END_POS) {
		my $new_data_pos = $self->{_data_pos} + length($char);
		my $cur_col = $new_data_pos - $self->{_scroll_pos};
		if($cur_col >= $self->canvas_columns) {
			$self->right();
		}
		$self->{_data_pos} = $new_data_pos;
		$self->{_old_scroll_pos} = -1;
	} else {
		$self->end();
	}
	
}

sub process_event {
	my $self = shift;
	my %opt = @_;
	my $old_text = $self->text();
	if(exists $opt{keypress}) {
		$self->process_key($opt{keypress});
	}
	my %callback_opt;
	$callback_opt{text} = $self->text() if $old_text ne $self->text();
	$opt{callback}->update(%callback_opt);
	$self->log()->info(Dumper($self->pos()));
	$self->log()->info(unctrl($opt{keypress}));
}

sub update {
	my $self = shift;

	$self->window()->clear();
	my $columns = $self->canvas_columns();
	my $cur_col = $self->{_data_pos} - $self->{_scroll_pos};
	my $string = substr $self->text(), $self->{_scroll_pos}, $columns;
	$self->window()->addstr(0,0, $string);
	$self->window()->move(0, $cur_col);
	$self->SUPER::update();

	$self->WINCH(0);
	$self->{_old_scroll_pos} = $self->{_scroll_pos};
}

sub process_key {
	my $self = shift;
	my $keypress = shift;
	given($keypress) {
		when( uc(unctrl($_)) eq '^U' ) {
			$self->delete_to_bol();
		}
		when( uc(unctrl($_)) eq '^K' ) {
			$self->delete_to_eol();
		}
		when( uc(unctrl($_)) eq '^A' ) {
			$self->{_data_pos} = $self->{_scroll_pos};
		}
		when( uc(unctrl($_)) eq '^E' ) {
			$self->{_data_pos} = min( length($self->text()),
				$self->{_scroll_pos}+$self->canvas_columns()-1
			);
		}
		when( ord($_) == 10 ) {
			# TODO
			my ($cury, $curx);
			$self->window()->getyx($cury, $curx);
			$self->log()->info("Current pos $cury, $curx");
			$self->log()->info("Return key not implemented");
			$self->window()->move($cury, $curx);
			$self->window()->refresh();
		}
		when ( $_ !~ /\d{2,}/ ) {
			my $char = unctrl($_);
			$self->addchar($char);
			$self->log()->info("Adding character $_");
		}
		when( KEY_DC ) {
			# delete
			$self->delete_char_right();
		}
		when( KEY_BACKSPACE ) {
			my $del = $self->delete_char_left();
			$self->log()->info("Deleting character $del") if $del;
		}
		when( $_ ~~ KEY_UP || $_ ~~ KEY_HOME ) {
			$self->home();
		}
		when( $_ ~~ KEY_DOWN || $_ ~~ KEY_END ) {
			$self->end();
		}
		when( KEY_LEFT ) {
			$self->left();
		}
		when( KEY_RIGHT ) {
			$self->right();
		}
	}
	$self->log()->info(Dumper($self->{_text}));
}

1;
