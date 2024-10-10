swob (sway+wob helper)
======================

This is a simple/stupid helper script and config files to provide volume and
brightness controls under Wayland using [wob]. Sway is *not* mandatory (the
helper script doesn't depend on sway or any wlroots features) but a sway
config snippet is provided for convenience.

[wob]: https://github.com/francma/wob

Calling wob from a script or config file is not too intuitive, because it
panics if the process it's reading from hangs up. The helper script ensures
that there is a process keeping wob open for a few seconds to allow it to
time out, and potentially respond without invoking a whole new wob instance
on successive taps of the volume/brightness controls, especially with pauses
between. It doesn't go the way of keeping an always-open wob instance,
instead trying to balance invoking as needed with not starting a whole new
binary unnecessarily with every tap.

Dependencies
------------

- POSIX sh, sed and mkfifo(1); non-POSIX mktemp(1) (all pretty universally available)
- [wob]
- [amixer (from alsa-utils)](https://www.alsa-project.org)
- [brightnessctl](https://github.com/Hummer12007/brightnessctl)

Installation
------------

<ul>
<li>
Configure your wayland compositor to bind the XF86 volume/brightness
controls to swob.sh. Example configuration is provided for the following:
<dl>
<dt>Sway (options):</dt>
<dd>Copy the sway config snippet into your own sway config file...</dd>
<dd><em>Or</em> source it from that file...</dd>
<dd><em>Or</em> copy it into /etc/sway/config.d</dd>
<dt>dwl:</dt>
<dd>An example patch for config.h is available at <a
href="dwl-config.h.patch">dwl-config.h.patch</a></dd>
</dl>
</li>
<li> Put swob.sh on your PATH, or your wayland compositor's config to point to
     its exact location. </li>
</ul>

Copying
-------

Copyright &copy; 2024 The Remph <lhr@disroot.org>

These files are free software; the Remph gives unlimited permission to copy
and/or distribute them, with or without modification, as long as this notice
is preserved.

This software is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY, to the extent permitted by law; without even the
implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
