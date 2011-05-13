function cde {
	# NOTE: parallel runs not expected, uses same file
	GO="$HOME/bin/ecd.go"
	rm "$GO"
	ecd.exec "$GO"
	pushd .
	if [ -r "$GO" ]; then
		. "$GO"
	fi
}
