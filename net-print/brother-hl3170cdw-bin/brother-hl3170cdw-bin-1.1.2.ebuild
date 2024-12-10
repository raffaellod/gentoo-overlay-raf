#! /bin/sh
#
# Brother Print filter
# Copyright (C) 2005-2012 Brother. Industries, Ltd.

EAPI=7
DESCRIPTION='Driver for Brother HL-3170CDW printers'
HOMEPAGE='http://support.brother.com'

inherit rpm linux-info multilib

# Links from http://support.brother.com/g/s/id/linux/en/download_prn.html#HL-3170CDW
SRC_URI='
	http://www.brother.com/pub/bsc/linux/dlf/hl3170cdwlpr-1.1.2-1.i386.rpm
	http://www.brother.com/pub/bsc/linux/dlf/hl3170cdwcupswrapper-1.1.2-1.i386.rpm
'

LICENSE='brother-eula GPL-2'
SLOT=0
KEYWORDS='amd64 x86'

IUSE='avahi'
RESTRICT='mirror strip'

RDEPEND='
	net-print/cups
	avahi? ( net-dns/avahi sys-auth/nss-mdns )
'
DEPEND="${RDEPEND}"

S="${WORKDIR}"

pkg_setup() {
	if use amd64; then
		CONFIG_CHECK="${CONFIG_CHECK} ~IA32_EMULATION"
		if ! has_multilib_profile; then
			die 'This package required IA-32 emulation; please switch to a suitable profile.'
		fi
	else
		CONFIG_CHECK=
	fi

	linux-info_pkg_setup
}

src_unpack() {
	rpm_unpack ${A}
	# Delete the install script that this ebuild replaces.
	rm opt/brother/Printers/hl3170cdw/cupswrapper/cupswrapperhl3170cdw
}

src_install() {
	dosbin usr/bin/brprintconf_hl3170cdw
	cp -a "${S}/opt" "${D}/" || die 'could not install /opt files'
	local optbase=../../../../opt/brother/Printers/hl3170cdw
	dosym ${optbase}/lpd/filterhl3170cdw                          usr/libexec/cups/filter/brother_lpdwrapper_hl3170cdw
	dosym ${optbase}/cupswrapper/brother_hl3170cdw_printer_en.ppd usr/share/cups/model/brother_hl3170cdw_printer_en.ppd
}

pkg_postinst() {
   [ -e "${ROOT}/etc/init.d/cupsd" ] && "${ROOT}/etc/init.d/cupsd" restart

   einfo 'To install the printer, run:'
   einfo '  lpadmin -p HL-3170CDW -E -v ${printer_uri} -P /opt/brother/Printers/hl3170cdw/cupswrapper/brother_hl3170cdw_printer_en.ppd'
}

pkg_prerm() {
   lpadmin -x HL-3170CDW
   [ -e "${ROOT}/etc/init.d/cupsd" ] && "${ROOT}/etc/init.d/cupsd" restart
}
