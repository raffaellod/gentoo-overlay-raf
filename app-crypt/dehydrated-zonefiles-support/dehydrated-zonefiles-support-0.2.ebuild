# Copyright 2024 Raffaello D. Di Napoli <rafdev@dinapo.li>
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION='DNS zonefile consumer/updater for dehydrated'
HOMEPAGE='https://github.com/raffaellod/dehydrated-zonefiles-support'
LICENSE='GPL-2'

if [[ ${PV} == 9999 ]]; then
	inherit git-r3
	EGIT_REPO_URI='https://github.com/raffaellod/dehydrated-zonefiles-support.git'
	#EGIT_COMMIT="v${PV}"
else
	SRC_URI="https://github.com/raffaellod/dehydrated-zonefiles-support/archive/v${PV}.tar.gz -> ${P}.tar.gz"
fi

SLOT=0
KEYWORDS='~amd64 ~x86'
IUSE='+cron'
RESTRICT='mirror'

RDEPEND="
	app-crypt/dehydrated
	cron? (
		virtual/cron
		app-crypt/dehydrated[-cron]
	)
"
DEPEND="${RDEPEND}"

src_install() {
	dobin dehydrated-zonefiles-wrapper

	exeinto /usr/libexec
	doexe dehydrated-zonefiles-hook

	insinto /etc/dehydrated/config.d
	doins etc/dehydrated/config.d/50-zonefiles_support

	if use cron; then
		exeinto /etc/cron.daily
		doexe etc/cron.daily/dehydrated
	fi
}

src_test() {
	./test
}
