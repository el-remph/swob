#!/bin/bash
# SPDX-FileCopyrightText:  2023-2024 The Remph <lhr@disroot.org>
# SPDX-License-Identifier: GPL-3.0-or-later

# For the benefit of runit logging
exec 2>&1

set ${BASH_VERSION:+-o pipefail} -efmu

wobini=
set_wobini() {
	for dir in ${XDG_CONFIG_HOME:+"$XDG_CONFIG_HOME"} ~/.config /etc; do
		if test -r "$dir"/swob/wob.ini; then
			wobini=$dir/swob/wob.ini
			return
		fi
	done

	# fine, I will make my own wob.ini(5)
	wobini=${XDG_CONFIG_HOME:-~/.config}/swob/wob.ini
	echo >&2 "$0: no swob/wob.ini found; writing default to $wobini"
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

glob_match() {
	# MUST be called with set +f
	test $# -gt 1 -o -e "$1"
}

get_audio_type() {
	# MUST be called with set +fu

	case $SWOB_AUDIO in
	pipewire|pulse|alsa)	return ;;
	'')	;;
	*)	echo >&2 "$0: warning: unrecognised SWOB_AUDIO: $SWOB_AUDIO" ;;
	esac

	# could guess at /run/user/`id -u`, but let's not jump the gun here
	rundir=${PIPEWIRE_RUNTIME_DIR:-$XDG_RUNTIME_DIR}
	if test -n "$rundir" && glob_match "$rundir"/pipewire*; then
		SWOB_AUDIO=pipewire
		return
	fi

	rundir=${PULSE_RUNTIME_PATH:-$XDG_RUNTIME_DIR}
	if test -n "$rundir" && glob_match "$rundir"/pulse*; then
		SWOB_AUDIO=pulse
		return
	fi

	# default to ALSA
	SWOB_AUDIO=alsa
}

set_vol() {
	set +fu
	get_audio_type
	set -fu

	case $SWOB_AUDIO in
	pipewire)
		case $1 in
		toggle)	to_set=mute ;;
		*)	to_set='volume -l 1.0' ;;
		esac
		wpctl set-$to_set @DEFAULT_AUDIO_SINK@ "$1"
		wpctl get-volume @DEFAULT_AUDIO_SINK@ | sed -E \
			-e 's/^Volume: ([0-9]+)\.([0-9][0-9])/\1\2/'	\
			-e 's/\[MUTED\]/mute/'
		;;

	pulse)
		case $1 in
		toggle)	to_set=mute ;;
		*)	to_set=volume ;;
		esac
		pactl set-sink-$to_set @DEFAULT_SINK@ "$(echo "$1" | sed -E 's/(.*)([+-])$/\2\1/')"
		percent=`pactl get-sink-volume @DEFAULT_SINK@ | sed -En 's/.* ([0-9]+)%.*/\1/p'`
		mute_cmd='pactl get-sink-mute @DEFAULT_SINK@'
		mute_out=`$mute_cmd`
		case $mute_out in
		'Mute: yes')	muted=1 ;;
		'Mute: no')	muted= ;;
		*)	echo >&2 "$0: warning: bad output from $mute_cmd: $mute_out" ;;
		esac
		echo "$percent ${muted:+mute}"
		;;

	*)
		if test "$SWOB_AUDIO" != alsa; then
			echo >&2 "$0: WARNING: internal inconsistency! SWOB_AUDIO: \`$SWOB_AUDIO'"
		fi

		amixer sset Master "$1" | sed -E '
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
s/$/ volume/'
		;;
	esac
}

do_cmd_get_percent() {
	case $1 in
	volume|vol)
		set_vol "$2"
		;;
	brightness|brt)
		brightnessctl -m set "$2" | sed -En 's/(.*[^0-9])?([0-9]+)%.*/\2 brightness/p'
		;;
	*)
		echo >&2 "$0: error: unrecognised argument: $1"
		exit -1
		;;
	esac
}

## MAIN ##

# If not already made by the caller (which it should have been), make fifo
# ASAP, so the caller can write to it and not fail (or worse, creat(2) a
# regular file by accident, although this would be their own fault for not
# checking)
wobfifo=$XDG_RUNTIME_DIR/wob
test -p "$wobfifo" || mkfifo -m 0600 "$wobfifo" # possible race between these two
trap 'rm "$wobfifo"' 0

set_wobini

# Timeout needs to be long enough that there aren't too many wob(1)
# processes spawned and respawned consecutively on repeated taps,
# but short enough that there aren't too many /bin/sh processes hanging
# around simultaneously running sleep(1) from this script! 3 seconds is an
# uneducated guess.
timeout=3

# horrifying, but totally POSIX-kosher
tail -c +1 -f "$wobfifo" | {
	# FIXME: read -t is a bashism! Also doesn't work
	while read -t $timeout; do
		set -- $REPLY # word split
		if test $# -ne 2; then
			echo >&2 "$0: error: wrong number of arguments: $#"
			continue
		fi
		do_cmd_get_percent "$@"
	done

	exit # necessary else the other processes in the pipeline will shamble on
} | wob -c "$wobini" -v
