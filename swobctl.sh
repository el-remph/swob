#!/bin/sh
set -efu # +m

if test $# -ne 2; then
	echo >&2 "$0: error: wrong number of arguments: $#"
	exit 1
fi

SVDIR=${SVDIR-~/.runit/runsvdir/current} sv -v once swob

wobfifo=$XDG_RUNTIME_DIR/wob
if test ! -p "$wobfifo"; then
	echo >&2 "$0: no such FIFO"
	exit 1
fi

exec 3>$wobfifo
flock 3
echo >&3 "$@"
# no need to un-flock(1), I think

## Alternative: literal race between these two (requires set -m)
#{ sleep 5; kill -alrm $$; } &
#echo >$wobfifo "$@"; kill -term $!
