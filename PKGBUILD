pkgname=swob-git
pkgver=0
pkgrel=1
pkgdesc='Volume and brightness controls for wayland, using wob'
arch=(any) # limited only by dependencies
depends=(sh coreutils sed wob alsa-utils brightnessctl)
url='https://github.com/el-remph/swob'
license=(GPL-3.0-or-later)
provides=(swob)
source=("git+$url")
b2sums=(SKIP)

pkgver() (
	cd swob
	set -o pipefail
	git describe --long --abbrev=7 --tags 2>/dev/null |
		sed -e 's/^v//' -e 's/[^-]*-g/r&/' -e y/-/./ ||
			printf "r%s.%s" "$(git rev-list --count HEAD)" "$(git rev-parse --short=7 HEAD)"
)

package() {
	cd swob
	DESTDIR=$pkgdir ./install.sh
}
