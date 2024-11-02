#!/bin/sh
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
