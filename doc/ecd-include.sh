function cde {
	GO="$HOME/bin/ecd.go"
	ecd.exec "$GO"
	pushd .
	DIR=`xargs -d '\n' dirname < "$GO"`
	cd "$DIR";
}
