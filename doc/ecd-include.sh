function cde {
	# NOTE: parallel runs not expected, uses same file
	GO="$HOME/bin/ecd.go"
	rm "$GO" 2>/dev/null
	ecd.exec "$GO"
	if [ -r "$GO" ]; then
		pushd .
		. "$GO"
	fi
}
