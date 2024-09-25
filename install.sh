#!/bin/sh
set -ex
install -m 644 -Dt "$DESTDIR"/etc/sway/config.d/ swob-swayconfig
install -D -m 644 swob-wob.ini "$DESTDIR"/etc/swob/wob.ini
install -Dt "$DESTDIR"/usr/bin swob.sh
