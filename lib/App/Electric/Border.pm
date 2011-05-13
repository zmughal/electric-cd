package App::Electric::Border;

sub _top_border_ASCII {
	my ($ls, $rs, $ts, $bs, $tl, $tr, $bl, $br) = qw{ | | - - / \ + + };
}

sub _bottom_border_ASCII {
	my ($ls, $rs, $ts, $bs, $tl, $tr, $bl, $br) = qw{ | | - - + + \ / };
}

sub _top_border_ACS {
	my ($ls, $rs, $ts, $bs, $tl, $tr, $bl, $br) = (ACS_VLINE, ACS_VLINE,
		ACS_HLINE, ACS_HLINE, ACS_ULCORNER, ACS_URCORNER, ACS_LTEE,
		ACS_RTEE);
}

sub _bottom_border_ACS {
	my ($ls, $rs, $ts, $bs, $tl, $tr, $bl, $br) = (ACS_VLINE, ACS_VLINE,
		ACS_HLINE, ACS_HLINE, ACS_LTEE, ACS_RTEE, ACS_LLCORNER,
		ACS_LRCORNER);
}

1;
