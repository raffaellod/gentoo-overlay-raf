# Copyright 1999-2007 Gentoo Foundation
# Copyright 2012 Raffaello D. Di Napoli <rafdev@dinapo.li>
# Distributed under the terms of the GNU General Public License v2

DESCRIPTION="PHP bindings for the SQLite database engine."
HOMEPAGE="http://pecl.php.net/SQLite"
LICENSE="PHP"

KEYWORDS="alpha amd64 arm hppa ia64 ppc ppc64 s390 sh sparc x86"
SLOT="0"

SRC_URI="http://pecl.php.net/get/SQLite-${PV}.tgz"
S="${WORKDIR}/SQLite-${PV}"

IUSE=""

RDEPEND="
	=dev-db/sqlite-2*
	=dev-lang/php-4*
"

DEPEND="${RDEPEND}
	>=sys-devel/m4-1.4.3
	>=sys-devel/libtool-1.5.18
"


inherit eutils flag-o-matic autotools


src_unpack() {
	unpack ${A}
	cd "${S}"

	# Create configure out of config.m4 .
	/usr/$(get_libdir)/php4/bin/phpize
	# Force run of libtoolize and regeneration of related autotools files
	# (bug 220519).
	rm aclocal.m4
	eautoreconf
}


src_compile() {
	libdir=$(get_libdir)
	PHP_V=$(best_version =dev-lang/php-4*)
	addpredict /usr/share/snmp/mibs/.index
	addpredict /session_mm_cli0.sem

	commonconf="--prefix=/usr/${libdir}/php4 --with-php-config=/usr/${libdir}/php4/bin/php-config --with-sqlite=/usr"

	built_with_use =${PHP_V} apache2 concurrentmodphp && append-ldflags "-Wl,--version-script=${ROOT}/var/lib/php-pkg/${PHP_V}/php4-ldvs"

	# First compile run: the default one.
	econf ${commonconf} || die "Unable to configure code to compile"
	emake || die "Unable to make code"
	mv -f "modules/sqlite.so" "${WORKDIR}/sqlite-default.so" || die "Unable to move extension"

	if built_with_use =${PHP_V} apache2 concurrentmodphp; then
		# Need to clean up.
		make distclean || die "Unable to clean build environment"

		# Second compile run: the versioned one.
		econf ${commonconf} || die "Unable to configure versioned code to compile"
		sed -e "s|-Wl,--version-script=${ROOT}/var/lib/php-pkg/${PHP_V}/php4-ldvs|-Wl,--version-script=${ROOT}/var/lib/php-pkg/${PHP_V}/php4-ldvs -Wl,--allow-shlib-undefined -L/usr/${libdir}/apache2/modules/ -lphp4|g" -i Makefile
		append-ldflags "-Wl,--allow-shlib-undefined -L/usr/${libdir}/apache2/modules/ -lphp4"
		emake || die "Unable to make versioned code"
		mv -f "modules/sqlite.so" "${WORKDIR}/sqlite-versioned.so" || die "Unable to move versioned extension"
	fi
}


src_install() {
	addpredict /usr/share/snmp/mibs/.index

	phpextdir="$(/usr/$(get_libdir)/php4/bin/php-config --extension-dir 2>/dev/null)"

	# Let's put the default module away.
	insinto "${phpextdir}"
	newins "${WORKDIR}/sqlite-default.so" "sqlite.so" || die "Unable to install extension"

	# And now the versioned one, if it exists.
	if built_with_use =$(best_version =dev-lang/php-4*) apache2 concurrentmodphp; then
		insinto "${phpextdir}-versioned"
		newins "${WORKDIR}/sqlite-versioned.so" "sqlite.so" || die "Unable to install extension"
	fi

	for sapi in apache2 cli cgi; do
		etcphpsapidir=etc/php/${sapi}-php4
		if [ -f /${etcphpsapidir}/php.ini ]; then
			# Add the needed lines to the <ext>.ini file.
			[ ! -d ${etcphpsapidir}/ext ] && mkdir -p ${etcphpsapidir}/ext
			echo "extension=sqlite.so" >> ${etcphpsapidir}/ext/sqlite.ini
			einfo "Extension added to /${etcphpsapidir}/ext/sqlite.ini"
			insinto /${etcphpsapidir}/ext
			doins ${etcphpsapidir}/ext/sqlite.ini

			# Symlink the <ext>.ini file from ext/ to ext-active/
			dodir /${etcphpsapidir}/ext-active/
			dosym /${etcphpsapidir}/ext/sqlite.ini /${etcphpsapidir}/ext-active/sqlite.ini
		fi
	done

	phpdocdir=/usr/share/doc/${CATEGORY}/${PF}/
	insinto ${phpdocdir}
	for doc in "${WORKDIR}/package.xml" CREDITS; do
		if [ -s "${doc}" ]; then
			doins "${doc}"
			gzip -f -9 "${D}/${phpdocdir}/${doc##*/}"
		fi
	done
}
