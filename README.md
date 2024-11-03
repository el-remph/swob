This is a branch of swob where the rendezvous with the listener and loggging
are handled by your neighbourhood user service manager. User services are
supported by (if you must) systemd, [s6], [runit] and [dinit]; swob currently
supports:

- [runit version](service/sv) is a '''working''' mockup, but initialisation
  of the one-time service is too slow.
- [dinit version](service/dinit.d) also works, although logging is TODO. Its
  initialisation is much faster, but still not as fast as I'd like.

[s6]: https://skarnet.org/software/s6/
[runit]: https://smarden.org/runit/
[dinit]: https://davmac.org/projects/dinit/

-------------------------------------------------------------------------------

swob (sway+wob helper)
======================

This is a simple/stupid helper script and config files to provide volume and
brightness controls under Wayland using [wob]. Sway is *not* mandatory (the
helper script doesn't depend on sway or any wlroots features); the name is
simply because sway was the first compositor I configured this for. Other
compositor configurations are available; see [&sect;Installation](#installation).

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

- POSIX sh, sed and mkfifo(1); non-POSIX mktemp(1) (all pretty universally
  available)
- [wob]
- [brightnessctl](https://github.com/Hummer12007/brightnessctl)
- For volume, at least one of:
  - amixer, for [ALSA](https://www.alsa-project.org)
  - [wireplumber and wpctl](https://pipewire.pages.freedesktop.org/wireplumber)
    for pipewire
  - pactl for [PulseAudio](https://www.freedesktop.org/wiki/Software/PulseAudio)
    - As with anything pertaining to Poettering, pactl doesn't play nice,
      so the pactl backend is the slowest of the three: requires three calls
      to pactl and two to sed, compared with two calls to wpctl and one to
      amixer (each with only one call to sed). It is generally recommended to
      use one of the other two wherever possible

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

This program is free software: you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation, either version 3 of the License, or (at your option)
any later version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

A copy of the full GPL can be found at <https://www.gnu.org/licenses/GPL>.

As an additional permission under GNU GPL version 3 section 7, the section 4
requirement to distribute a copy of the GPL along with the work is waived,
provided that the above notices are distributed intact instead.
