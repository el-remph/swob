#!/bin/sh
# This script is pretty bad. The first part assumes user is root, but then
# the services bit assumes the user is a regular user, and is also no good
# for eg. PKGBUILD use
set -exuf +m

: "${DESTDIR:=}"

mkdir -p "$DESTDIR"/etc/sway/config.d/ "$DESTDIR"/etc/swob/
for i in swayconfig wob.ini; do
	install -m 644 swob-$i "$DESTDIR"/etc/swob/$i
done
ln -s ../../swob/swayconfig "$DESTDIR"/etc/sway/config.d/swob-swayconfig
install -Dt "$DESTDIR"/usr/bin swobd.sh swobctl.sh # Should swobd be in libexec?
install -m644 -Dt "$DESTDIR"/usr/share/doc/swob README.md dwl-config.h.patch

SV=${RUNIT_PREFIX:-~/.runit}/sv/swob
mkdir "$SV" # not -p; you should already have user services set up
ln -s "$SV"/run /usr/bin/swobd.sh
touch "$SV"/down
ln -s "$SV"/supervise "$XDG_RUNTIME_DIR"/supervise.swob/

dinit_usersvc_install() {
	# see dinit(8) section FILES
	for i in	\
		${DINIT_PREFIX:+"$DINIT_PREFIX"/dinit.d}	\
		${XDG_CONFIG_HOME:+"$XDG_CONFIG_HOME"/dinit.d}	\
		~/.config/dinit.d}	\
		/etc/dinit.d/user	\
		/usr/lib/dinit.d/user	\
		/usr/local/lib/dinit.d/user
	do
		if test -d "$i"; then
			install -m 644 -t "$i" service/dinit.d/swob
			return
		fi
	done

	echo >&2 "$0: error: No dinit directory found"
	return 1
}

dinit_usersvc_install
