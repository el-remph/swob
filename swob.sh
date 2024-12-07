#!/bin/sh
# SPDX-FileCopyrightText:  2023-2024 The Remph <lhr@disroot.org>
# SPDX-License-Identifier: GPL-3.0-or-later

set ${BASH_VERSION:+-o pipefail} -efmu
wobfifo=$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY.swob
wobini=
pid=$$	# So log messages appear as coming from this process, rather than a
	# a subprocess

# setup logger(1) to take any stderr warnings from this program (eg. command
# not found)
syslog=`mktemp -u`
mkfifo -m600 "$syslog"
# logger(1) and exec must be in this order, else they'll deadlock
logger -t swob -p user.warn -s --skip-empty --prio-prefix --id=$pid <$syslog &
exec 2>$syslog
rm "$syslog"	# unlink fifo; the file descriptor will remain open

complain() {
	case $1 in
	emerg*)	prio=0 ;;
	alert)	prio=1 ;;
	crit*)	prio=2 ;;
	err*)	prio=3 ;;
	warn*)	prio=4 ;;
	notice)	prio=5 ;;
	info*)	prio=6 ;;
	debug)	prio=7 ;;
	esac
	shift
	printf >&2 '<%d>%s\n<4>\n' $prio "$*" # send message, then immediately reset syslog level to warn
}

set_wobini() {
	for dir in ${XDG_CONFIG_HOME:+"$XDG_CONFIG_HOME"} ~/.config /etc; do
		if test -r "$dir"/swob/wob.ini; then
			wobini=$dir/swob/wob.ini
			return
		fi
	done

	# fine, I will make my own wob.ini(5)
	wobini=${XDG_CONFIG_HOME:-~/.config}/swob/wob.ini
	complain notice "no swob/wob.ini found; writing default to $wobini"
	mkdir -p "${wobini%/*}"
	cat >$wobini <<EOF
[style.volume]
background_color = 000000

[style.mute]
background_color = af0000

[style.brightness]
background_color = a89800
EOF
}

start_wob() {
	if test -e "$wobfifo"; then
		return	# Already started
	fi

	# temporary fifo (call mkfifo(1) asap to minimise possibility of races)
	# TODO: should this be in C, so we can call mkfifo(2) and check for
	# EEXIST, rather than using test(1)? Alternatively, there is flock(1),
	# or any other IPC or SHM system
	mkfifo -m600 "$wobfifo"

	set_wobini

	# spawn wob process with temporary file(s)
	{
		trap 'rm "$wobfifo"' 0
		# Don't `exec' wob here, else the trap won't work
		# wob's kvetching gets redirected to debug priority instead
		# of being allowed to fallthrough to the default logger(1),
		# which sets priority to warn
		wob -c "$wobini" -v <$wobfifo 2>&1 | while read REPLY; do
			complain debug "$REPLY"
		done
	} &
}

do_cmd_get_percent() {
	case $1 in
		volume|vol)
			amixer sset Master "$2" | sed -E '
# Extract percentage, keep original line for later
h
s/.*\[([0-9]+)%\].*/\1/
t match
d

: match
# Get original line back
x
# Test if audio is muted
/\[off\]/ {
	g
	s/$/ mute/
	b
}
# else
g
s/$/ volume/
'		;;
		brightness|brt)
			brightnessctl -m set "$2" | sed -En 's/(.*[^0-9])?([0-9]+)%.*/\2 brightness/p'
			;;
		*)
			complain error "unrecognised argument: $target"
			exit -1
			;;
	esac
}

## MAIN ##

start_wob

{
	do_cmd_get_percent "$@"
	sleep 3	# Needs to be long enough that there aren't too many wob(1)
		# processes spawned and respawned consecutively on repeated
		# taps, but short enough that there aren't too many /bin/sh
		# processes hanging around simultaneously running sleep(1)
		# from this script! 3 seconds is an uneducated guess.
} >$wobfifo

# Don't let wob die if it's still receiving input from another process; wait
# until it says it's finished
# To solve the above mentioned problem of too many /bin/sh processes hanging
# around, we could setsid(1) wob so the script can exit without waiting as
# soon as it's done sleeping (the existing situation is that as long as one
# script sleeps, the shell that spawned the wob process will wait until that
# sleep is done)
#
# $wobini is tested because it's null-init'd, then only set if start_wob
# doesn't short-circuit. Works in dash but not bash, because of how they name
# jobspecs:
#	if jobs %trap >/dev/null; then wait %trap; fi
test -z "$wobini" || wait $!
