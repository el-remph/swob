#!/bin/sh
set -efu # +m

die() {
	echo >&2 "$0: $*"
	exit 1
}


test $# -eq 2 || die "error: wrong number of arguments: $#"

wobfifo=$XDG_RUNTIME_DIR/wob
test -p "$wobfifo" || mkfifo -m600 "$wobfifo" # possible race between these two

if test -n "${SVDIR-}"; then
	sv -v once swob
elif test -n "${DINIT_SOCKET_PATH-}" -o -S "$XDG_RUNTIME_DIR"/dinitctl -o -S ~/.dinitctl; then
	dinitctl start swob
else
	die "$0: No service manager found"
fi

exec 3>$wobfifo
flock 3
echo >&3 "$@"
# no need to un-flock(1), I think

## Alternative: literal race between these two (requires set -m)
#{ sleep 5; kill -alrm $$; } &
#echo >$wobfifo "$@"; kill -term $!
