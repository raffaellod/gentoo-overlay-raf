# Copyright 2024 Raffaello D. Di Napoli <rafdev@dinapo.li>
# Partly based on work by:
# ‣  author unknown, credited to “Gentoo Authors” (ostensibly GPLv2)
# ‣  Armas Spann, but likely based on above (GPLv2)
# •  Benjamin Neff, also likely based on the first (GPLv2)
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake desktop udev xdg

DESCRIPTION='DSO software for Hantek USB digital signal oscilloscopes 6022BE/BL'
HOMEPAGE='https://github.com/OpenHantek/OpenHantek6022'
LICENSE='GPL-3'

RESTRICT='mirror'
SLOT=0
KEYWORDS='~amd64'

SRC_URI="https://github.com/OpenHantek/OpenHantek6022/archive/${PV}.tar.gz -> ${P}.tar.gz"

BDEPEND="
	>=dev-qt/linguist-tools-5.4
	>=dev-util/cmake-3.5
"
RDEPEND="
	>=dev-qt/qtopengl-5.4
	>=dev-qt/qtprintsupport-5.4
	>=dev-qt/qtwidgets-5.4
	>=sci-libs/fftw-3
	virtual/libusb:1
"
DEPEND="
	${RDEPEND}
"

S="${WORKDIR}/OpenHantek6022-${PV}"

src_install () {
	cmake_src_install
	mv ${D}/usr/share/doc/openhantek ${D}/usr/share/doc/${P}
}

pkg_postinst() {
	xdg_icon_cache_update
	udev_reload
}

pkg_postrm() {
	xdg_icon_cache_update
	udev_reload
}
