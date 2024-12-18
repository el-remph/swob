#!/bin/sh
set -ex
: ${PREFIX=/usr} ${ETCDIR:=/etc}

for i in swayconfig wob.ini; do
	install -Dm 644 swob-$i "$DESTDIR$ETCDIR"/swob/$i
done

install -d "$DESTDIR$ETCDIR"/sway/config.d/
ln -s ../../swob/swayconfig "$DESTDIR$ETCDIR"/sway/config.d/swob-swayconfig

install -Dt "$DESTDIR$PREFIX"/bin swob.sh
install -m644 -Dt "$DESTDIR$PREFIX"/share/doc/swob README.md dwl-config.h.patch
