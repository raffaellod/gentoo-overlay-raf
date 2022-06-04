# Copyright 2021-2022 Raffaello D. Di Napoli <rafdev@dinapo.li>
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION='MOdular NETwork manager for Linux systems'
HOMEPAGE='https://github.com/raffaellod/monet'
LICENSE='GPL-2'

if [[ ${PV} == 9999 ]]; then
	inherit git-r3
	EGIT_REPO_URI='https://github.com/raffaellod/monet.git'
	#EGIT_COMMIT="v${PV}"
else
	SRC_URI="https://github.com/raffaellod/monet/archive/v${PV}.tar.gz -> ${P}.tar.gz"
fi

SLOT=0
KEYWORDS='~amd64 ~x86'
IUSE='dhcp dhcpd ipv6'
RESTRICT='mirror'

RDEPEND="
	|| ( sys-apps/iproute2 sys-apps/busybox[ip,ipv6?] )
	dhcp? ( || ( net-misc/dhcpcd[ipv6?] sys-apps/busybox[dhcp,ipv6?] ) )
	dhcpd? ( || ( net-dns/dnsmasq[dhcp,ipv6?] sys-apps/busybox[dhcpd,ipv6?] ) )
"
DEPEND="${RDEPEND}"

src_install() {
	newinitd init.d/${PN} ${PN}
	if use dhcp; then
		newinitd init.d/${PN}-dhcpc ${PN}-dhcpc
	fi
	if use dhcpd; then
		newinitd init.d/${PN}-dhcpd ${PN}-dhcpd
		newinitd init.d/${PN}-dnsmasq ${PN}-dnsmasq
	fi

	insinto /lib/${PN}
	doins lib/shared.shlib

	exeinto /lib/${PN}
	doexe lib/ifplugd-event
	doexe lib/start_scheduled_services_for
	if use dhcp; then
		doexe lib/dhcpcd-event
		doexe lib/udhcpc-event
	fi
	if use dhcpd; then
		doexe lib/dnsmasq-event
	fi

	keepdir /var/lib/${PN}
}
