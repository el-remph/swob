#!/bin/sh
set -ex
mkdir -p "$DESTDIR"/etc/sway/config.d/ "$DESTDIR"/etc/swob/
for i in swayconfig wob.ini; do
	install -m 644 swob-$i "$DESTDIR"/etc/swob/$i
done
ln -s ../../swob/swayconfig "$DESTDIR"/etc/sway/config.d/swob-swayconfig
install -Dt "$DESTDIR"/usr/bin swob.sh
install -m644 -Dt "$DESTDIR"/usr/share/doc/swob README.md dwl-config.h.patch
