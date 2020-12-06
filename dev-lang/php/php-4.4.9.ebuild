# Copyright 1999-2009 Gentoo Foundation
# Copyright 2012 Raffaello D. Di Napoli <rafdev@dinapo.li>
# Distributed under the terms of the GNU General Public License v2

EAPI=5

DESCRIPTION='The PHP language runtime engine: CLI, CGI and Apache2 SAPIs.'
HOMEPAGE='http://php.net/'
LICENSE=PHP-3

KEYWORDS='alpha amd64 arm hppa ia64 ppc ppc64 s390 sh sparc x86 x86-fbsd'
SLOT="4.9"
PHP_MV=${PV%%.*}

SRC_URI="http://www.php.net/distributions/${P}.tar.bz2"

SAPIS="cli cgi apache2"
CGI_SAPI_USE="discard-path force-cgi-redirect"
EXTENSIONS_USE="
	berkdb bzip2
	cdb cjk crypt curl
	exif expat
	firebird
	gd gd-external gdbm gmp
	iconv imap iodbc ipv6
	jpeg
	kerberos
	ldap libedit
	mcal mcve mhash mssql mysql
	ncurses nls
	odbc
	pcre png postgres
	readline
	snmp spell sqlite ssl sysvipc
	truetype
	unicode
	wddx
	xml xmlrpc xpm xsl
	zlib
"
IUSE="
	branding debug doc minimal pic sharedext threads
	+${SAPIS} ${CGI_SAPI_USE} ${EXTENSIONS_USE}
"
REQUIRED_USE="|| ( ${SAPIS} )"

# Extensions that pull in gd (internal) will also pull in whatever gd needs
# to support them; the same goes for other libs.
RDEPEND="
	app-eselect/eselect-php
	!dev-libs/9libs
	virtual/mta

	apache2? ( >=www-servers/apache-2[threads=] )

	berkdb? ( =sys-libs/db-4* )
	bzip2? ( app-arch/bzip2 )
	cdb? ( || ( dev-db/cdb dev-db/tinycdb ) )
	crypt? ( >=dev-libs/libmcrypt-2.4 )
	curl? ( >=net-misc/curl-7.10.5 )
	expat? ( dev-libs/expat )
	exif? ( !gd-external? ( media-libs/libpng app-arch/bzip2
		sys-libs/zlib ) )
	firebird? ( dev-db/firebird )
	gd? ( !gd-external? ( media-libs/libpng app-arch/bzip2
		sys-libs/zlib ) )
	gd-external? ( media-libs/gd[jpeg?,png?,truetype?,xpm?,zlib?] )
	gdbm? ( >=sys-libs/gdbm-1.8.0 )
	gmp? ( >=dev-libs/gmp-4.1.2 )
	iconv? ( virtual/libiconv )
	imap? ( virtual/imap-c-client[ssl=] )
	iodbc? ( >=dev-db/unixODBC-1.8.13 dev-db/libiodbc )
	jpeg? ( !gd-external? ( media-libs/libpng app-arch/bzip2 sys-libs/zlib
		 virtual/jpeg ) )
	kerberos? ( virtual/krb5 )
	ldap? ( >=net-nds/openldap-1.2.11 )
	libedit? ( || ( sys-freebsd/freebsd-lib dev-libs/libedit ) )
	mcal? ( >=dev-libs/libmcal-0.7-r5 )
	mcve? ( net-libs/libmonetra >=dev-libs/openssl-0.9.7 )
	mhash? ( app-crypt/mhash )
	mssql? ( dev-db/freetds )
	mysql? ( virtual/mysql )
	ncurses? ( sys-libs/ncurses )
	nls? ( sys-devel/gettext )
	odbc? ( >=dev-db/unixODBC-1.8.13 )
	pcre? ( >=dev-libs/libpcre-7.9[unicode] )
	png? ( !gd-external? ( media-libs/libpng app-arch/bzip2
		sys-libs/zlib ) )
	postgres? ( >=dev-db/libpq-7.1[threads?] )
	readline? ( !libedit? ( sys-libs/readline ) )
	snmp? ( >=net-analyzer/net-snmp-5.2 )
	spell? ( >=app-text/aspell-0.50 )
	ssl? ( >=dev-libs/openssl-0.9.7 )
	truetype? ( !gd-external? ( media-libs/libpng app-arch/bzip2
		sys-libs/zlib =media-libs/freetype-2*
		>=media-libs/t1lib-5.0.0 ) )
	wddx? ( >=dev-libs/libxml2-2.4.14 sys-libs/zlib )
	xml? ( >=dev-libs/libxml2-2.4.14 sys-libs/zlib )
	xmlrpc? ( dev-libs/expat )
	xpm? ( !gd-external? ( media-libs/libpng app-arch/bzip2 sys-libs/zlib
		x11-libs/libXpm ) )
	xsl? ( >=dev-libs/libxml2-2.4.14 sys-libs/zlib
		>=dev-libs/libxslt-1.0.18 app-text/sablotron )
	zlib? ( sys-libs/zlib )
"
DEPEND="
	${RDEPEND}
	>=sys-devel/m4-1.4.3
	>=sys-devel/libtool-1.5.18
"
PDEPEND="
	doc? ( app-doc/php-docs )
	sqlite? ( dev-php${PHP_MV}/pecl-sqlite )
"

inherit apache-module autotools depend.apache eutils flag-o-matic libtool toolchain-funcs

want_apache2

pkg_setup() {
	if [ ! -x "${ROOT}/usr/sbin/sendmail" ]; then
		elog "You need a virtual/mta that provides a sendmail compatible binary! All"
		elog "major MTAs provide this, and it's usually some symlink created as"
		elog "'${ROOT}/usr/sbin/sendmail*'. You should also be able to use other MTAs"
		elog "directly, but you'll have to edit the sendmail_path directive in your"
		elog "php.ini for this to work."
		elog
	fi

	depend.apache_pkg_setup
}

src_prepare() {
	epatch "${FILESDIR}/${P}-pack.patch"

	# Disable interactive make test.
	sed -i -e "s/\!getenv('NO_INTERACTION')/false/g" run-tests.php

	# Prevent PHP from activating the Apache config, as we will do
	# that ourselves.
	sed -i -e '
		s/-i -[Aa] -n php/-i -n php/
	' configure sapi/apache2{filter,handler}/config.m4

	if use branding; then
		# Show Gentoo as the server platform.
		sed -i -e '
			s/^EXTRA_VERSION=".*"/EXTRA_VERSION="-pl'${PR/r/}'-gentoo"/
			s/PHP_UNAME=`uname -a | xargs`/PHP_UNAME=`uname -s -n -r -v | xargs`/
		' configure.in || die 'Unable to brand PHP'
	fi
	if use postgres; then
		sed -i -e '
			s|include/postgresql|include/postgresql include/postgresql/pgsql|g
		' ext/pgsql/config.m4 ||
			die 'Failed to fix PostgreSQL include paths'
	fi
	if has_version app-crypt/heimdal; then
		# Support heimdal instead of mit-krb5.
		sed -i -e '
			s/gssapi_krb5/gssapi/g
			/PHP_ADD_LIBRARY(k5crypto, 1, $1)/ d
		' acinclude.m4 || die 'Failed to fix heimdal'
	fi
	if has_version '>=dev-libs/openssl-1'; then
		# LHASH * should not be used anymore, but void * works just
		# fine.
		sed -i -e 's/LHASH/void/g' ext/openssl/openssl.c ||
			die 'Failed to patch SSL code for OpenSSL-1'
	fi
	if has_version '>=sys-devel/autoconf-2.64'; then
		# Work around divert() issues with newer autoconf. Taken from
		# bug 281697 for PHP5.
		sed -i -re '
			s:^((m4_)?divert)[(]([0-9]*)[)]:\1(600\3):
		' $(grep -l divert $(find -name '*.m4') configure.in) ||
			die 'Failed to patch for recent autoconf'
	fi

	# We are heavily patching autotools base files (configure.in), so
	# let's regenerate the whole stuff now.

	# eaclocal doesn't accept --force, so we try to force re-generation
	# this way.
	rm aclocal.m4
	eautoreconf --force -W no-cross

	# Fix Makefile.global:test to consider the CGI SAPI if present.
	if use cgi; then
		# Note that this is NOT expanded now; it's just a replacement
		# to shorten the sed script.
		local tbdp='"$(top_builddir)/php-'
		sed -i -e "
			s|test \! -z ${tbdir}cli\" \&\& test -x ${tbdir}cli\"|test \! -z ${tbdir}cli\" \&\& test -x ${tbdir}cli\" \&\& test \! -z ${tbdir}cgi\" \&\& test -x ${tbdir}cgi\"|g
			s|TEST_PHP_EXECUTABLE=${tbdir}cli\"|TEST_PHP_EXECUTABLE=${tbdir}cli\" TEST_PHP_CGI_EXECUTABLE=${tbdir}cgi\"|g
		" Makefile.global
	fi
}


src_configure() {
	# Enable support for shared extensions, if required.
	local shext= extpathdelim='='
	if use sharedext; then
		shext='=shared'
		extpathdelim=','
	fi

	use_w() {
		if [ ${2} = - ] || use ${2}; then
			conf="${conf} --with-${3:-${2}}"
			if [ ${1} != no_sh ]; then
				conf="${conf}${shext}${4:+${extpathdelim}}${4}"
			else
				conf="${conf}${4:+=}${4}"
			fi
		else
			conf="${conf} --without-${3:-${2}}"
		fi
	}
	use_en() {
		if [ ${2} = - ] || use ${2}; then
			conf="${conf} --enable-${3:-${2}}"
			[ ${1} != no_sh ] && conf="${conf}${shext}"
		else
			conf="${conf} --disable-${3:-${2}}"
		fi
	}

	# Use the internal gd if USE=gd-external is not enabled, or gd
	# (implicitly -internal) or any extension requiring it are.
	if use !gd-external && {
		use exif || use gd || use jpeg ||
		use png || use truetype || use xpm
	}; then
		use_gd=true
	else
		use_gd=false
	fi
	# Force xml on if any extension requiring it is in USE.
	# xsl only requires xml for dom-xslt and dom-exslt, but who wants xsl
	# without xml?
	if use wddx || use xml || use xmlrpc || use xsl; then
		use_xml=true
	else
		use_xml=false
	fi

	conf=

	# Convert USE flags to configure flags (SAPI and related).
	#
	#		can_sh	USE flag	extension	external path
	#
	use_w		no_sh	apache2		apxs2		/usr/sbin/apxs2
	use_en		no_sh	cli
	use_en		no_sh	cgi
	use_en		no_sh	cgi		fastcgi
	if use cgi; then
		use_en	no_sh	discard-path
		use_en	no_sh	force-cgi-redirect
	fi
	if use amd64; then
		# Force -fPIC on amd64, or the build will break.
		use_w	no_sh	-		pic
	else
		use_w	no_sh	pic
	fi
	use_en		no_sh	debug
	use_en		no_sh	threads		experimental-zts

	# Convert USE flags to configure flags (extensions).
	#
	#		can_sh	USE flag	extension	external path
	#
	# Enable dba for cdb, db4, flatfile, gdbm, inifile.
	{ use cdb || use berkdb || use !minimal; } &&
		use_en	can_sh	-		dba
	{ ${use_gd} || ${use_xml} || use zlib; } &&
		use_w	no_sh	-		zlib-dir	/usr
	use_en		can_sh	!minimal	bcmath
	use_en		can_sh	!minimal	calendar
	use_en		can_sh	!minimal	ctype
	use_en		can_sh	!minimal	dbase
	use_en		can_sh	!minimal	dbx
	use_en		can_sh	!minimal	filepro
	use_w		no_sh 	!minimal	flatfile
	use_en		can_sh	!minimal	ftp
	use_w		no_sh 	!minimal	inifile
	use_en		no_sh	!minimal	memory-limit
	use_en		can_sh	!minimal	overload
	use_en		can_sh	!minimal	pcntl
	use_en		can_sh	!minimal	posix
	use_en		can_sh	!minimal	session
	use_en		can_sh	!minimal	sockets
	use_en		can_sh	!minimal	tokenizer
	use_w		no_sh 	berkdb		db4
	use_w		can_sh	bzip2		bz2
	use_w		no_sh	cdb
	use_w		can_sh	crypt		mcrypt
	use_w		can_sh	curl
	use_en		can_sh	expat		xml
	use_w		can_sh	firebird	interbase	/usr
	use_w		no_sh 	gdbm
	use_w		can_sh	gmp
	use_w		can_sh	iconv
	use_w		can_sh	imap
	use_w		no_sh	iodbc		iodbc		/usr
	use_en		can_sh	ipv6
	use_w		no_sh	kerberos	kerberos	/usr
	use_w		can_sh	ldap
	use_w		can_sh	libedit
	use_w		can_sh	mcal		mcal		/usr
	use_w		can_sh	mcve
	use_w		can_sh	mhash
	use_w		can_sh	mssql
	use_w		can_sh	mysql		mysql		/usr
	use_w		no_sh	mysql		mysql-sock	/var/run/mysqld/mysqld.sock
	use_w		can_sh	ncurses
	use_w		can_sh	nls		gettext
	if use iodbc; then
		use_w	no_sh	-		unixODBC	/usr
	else
		use_w	no_sh	odbc		unixODBC	/usr
	fi
	use_w		can_sh	pcre		pcre-regex	/usr
	use_w		can_sh	postgres	pgsql
	use !libedit &&
		use_w	can_sh	readline
	use_w		can_sh	spell		pspell
	use_w		can_sh	snmp
	use_w		can_sh	ssl		openssl
	use_w		no_sh	ssl		openssl-dir	/usr
	use imap &&
		use_w	can_sh	ssl		imap-ssl
	use_en		can_sh	sysvipc		sysvmsg
	use_en		can_sh	sysvipc		sysvsem
	use_en		can_sh	sysvipc		sysvshm
	use_en		can_sh	unicode		mbstring
	use_en		can_sh	wddx
	${use_xml} &&
		use_w	can_sh	-		dom
	use_w		can_sh	xmlrpc
	use_en		can_sh	xsl		xslt
	use_w		can_sh	xsl		xslt-sablot
	use_w		can_sh	xsl		dom-xslt	/usr
	use_w		can_sh	xsl		dom-exslt	/usr
	use_w		can_sh	zlib
	#
	# gd and gd-related extensions.
	if use gd-external; then
		use_en	no_sh	cjk		gd-jis-conv
		use_w	can_sh	gd-external	gd		/usr
	elif ${use_gd}; then
		use_en	no_sh	cjk		gd-jis-conv
		use_en	no_sh	exif
		use_w	no_sh	jpeg		jpeg-dir	/usr
		use_w	no_sh	png		png-dir		/usr
		use_w	no_sh	truetype	freetype-dir	/usr
		use_w	no_sh	truetype	t1lib		/usr
		use_w	no_sh	xpm		xpm-dir		/usr
		# Enable gd last, so configure can pick up the previous
		# settings.
		use_w	can_sh	-		gd
	fi

	# Bug 14067. Reverse the order to fix bug 32022 and bug 12021.
	replace-cpu-flags 'k6*' i586

	# Set the correct compiler for cross-compilation.
	tc-export CC

	local destdir=/usr/$(get_libdir)/php${SLOT}
	econf \
		--prefix="${EPREFIX}${destdir}" \
		--mandir="${EPREFIX}${destdir}/man" \
		--infodir="${EPREFIX}${destdir}/info" \
		--libdir="${EPREFIX}${destdir}/lib" \
		--cache-file=./config.cache \
		--disable-all \
		--without-pear \
		${conf}
}

src_compile() {
	emake

	# To keep the separate php.ini files for each SAPI, we change the
	# build-defs.h and recompile.
	for sapi in ${SAPIS}; do
		use ${sapi} || continue

		einfo "Building ${sapi} SAPI"
		sed -i -e '
			s|^\(#define PHP_CONFIG_FILE_PATH\).*|\1 "/etc/php/'${sapi}'-php'${PHP_MV}'"|
			s|^\(#define PHP_CONFIG_FILE_SCAN_DIR\).*|\1 "/etc/php/'${sapi}'-php'${PHP_MV}'/ext-active"|
		' main/build-defs.h
		rm -f main/{main,php_ini}.{,l}o
		if [ ${sapi} != apache2 ]; then
			make sapi/${sapi}/php ||
				die "Unable to make ${sapi} SAPI"
			cp sapi/${sapi}/php php-${sapi} ||
				die "Unable to copy ${sapi} SAPI"
		else
			make || die "Unable to make ${sapi} SAPI"
		fi
	done
}

src_install() {
	local destdir=/usr/$(get_libdir)/php${SLOT}

	use snmp &&
		addpredict /usr/share/snmp/mibs/.index

	# Install PHP, without any SAPIs.
	emake INSTALL_ROOT="${D}" install-{build,headers,programs}
	PHP_EXTDIR=$("${D}/${destdir}/bin/php-config" --extension-dir) ||
		die 'Unable to determine the extensions directory'
	# Install missing header files.
	dodir ${destdir}/include/php/ext/mbstring
	insinto ${destdir}/include/php/ext/mbstring
	doins ext/mbstring/mbregex/mbregex.h
	# Install shared extensions, if any.
	if use sharedext && [ "$(echo modules/*.so)" != 'modules/*.so' ]; then
		insinto "${PHP_EXTDIR}"
		doins modules/*.so
	fi

	# Create the directory where we'll put php${PHP_MV}-only PHP scripts.
	keepdir /usr/share/php${PHP_MV}

	local sapi
	for sapi in ${SAPIS}; do
		use ${sapi} || continue

		einfo "Installing ${sapi} SAPI"
		if [ ${sapi} = apache2 ]; then
			insinto ${destdir}/apache2
			doins libs/libphp${PHP_MV}.so
			keepdir /usr/$(get_libdir)/apache2/modules
		else
			into ${destdir}
			if [ ${sapi} = cli ]; then
				newbin php-${sapi} php
			else
				dobin php-${sapi}
			fi
		fi
		sapi_install_ini ${sapi}
	done

	# Install env.d files.
	newenvd "${FILESDIR}/20php${PHP_MV}-envd" 20php${SLOT}
	sed -i -e "
		s|/lib/|/$(get_libdir)/|g
		s|php${PHP_MV}|php${SLOT}|g
	" "${D}/etc/env.d/20php${SLOT}"

	# Install example PHP ini files into /usr/share/${P}.
	if [ -f php.ini-development ]; then
		# PHP >=5.3
		dodoc php.ini-development
		dodoc php.ini-production
	else
		# PHP 4/PHP <=5.2
		newdoc php.ini-dist php.ini-development
		newdoc php.ini-recommended php.ini-production
	fi
}

sapi_install_ini() {
	local sapi=${1}

	# Figure out where we'll install the ini file.
	local inidir="/etc/php/${sapi}-php${PHP_MV}"
	local iniextdir="${inidir}/ext"
	local iniextactivedir="${inidir}/ext-active"

	einfo 'Copying patched php.ini'
	sed -e '
		# Set the extension directory.
		s|^extension_dir .*|extension_dir = '"${PHP_EXTDIR}"'|

		# Set the include path to point to where we want to find PEAR
		# packages.
		s|^;include_path = ".:/php/includes".*|include_path = ".:/usr/share/php'${PHP_MV}':/usr/share/php"|

		# Default allow_url_open to off.
		s|^allow_url_fopen .*|allow_url_fopen = Off|
	' <php.ini-dist >php.ini-${sapi}

	if use mysql; then
		# Add needed MySQL extension charset configuration.
		local mycnfcharset=
		if [ -f "${ROOT}/etc/mysql/my.cnf" ]; then
			mycnfcharset=$(awk -vsSapiSection=${sapi} '
				BEGIN {
					if (sSapiSection == "cgi")
						sSapiSection = "cgi-fcgi"
					else if (sSapiSection == "apache2")
						sSapiSection = "apache2handler"
					sSapiSection = "php-" sSapiSection
				}
				/^[[:space:]]*\[([-_0-9a-z]+)\]/ {
					match($0, /\[(.*)\]/, arr)
					sSection = arr[1]
				}
				/^[[:space:]]*default-character-set[[:space:]]*=/ &&
				(sSection == "client" || sSection == sSapiSection) {
					if (match($0, /[^=]*=[[:space:]]*"?([0-9a-z][-0-9a-z]*)"?$/, arr))
						if (sSection == "client")
							sClientCharset = arr[1]
						else
							sSapiCharset = arr[1]
				}
				END {
					# If a SAPI-specific section with a
					# default-character-set value was
					# found, print it; otherwise print the
					# client charset (which may be empty).
					if (sSapiCharset)
						print sSapiCharset
					else
						print sClientCharset
				}
			' <"${ROOT}/etc/mysql/my.cnf")
		fi
		if [ -n "${mycnfcharset}" ]; then
			einfo "Setting MySQL extension charset to ${mycnfcharset}"
			mycnfcharset="mysql.connect_charset = ${mycnfcharset}"
		else
			mycnfcharset=';mysql.connect_charset = utf8'
		fi
		echo >>php.ini-${sapi} <<-EOF
			; MySQL extension default connection charset settings
			${mycnfcharset}
		EOF
	fi

	dodir ${inidir}
	dodir ${iniextdir}
	dodir ${iniextactivedir}
	insinto ${inidir}
	newins php.ini-${sapi} php.ini

	if use sharedext; then
		# Install any extensions built as shared objects.
		find "${D}/${PHP_EXTDIR}" -name '*.so' -printf '%f\n' |
		while read ext; do
			ini=${ext%.so}.ini
			echo "extension=${ext}" >>"${D}/${iniextdir}/${ini}"
			dosym "${iniextdir}/${ini}" "${iniextactivedir}/${ini}"
		done
	fi

	# Install SAPI-specific configuration files.
	if [ ${sapi} = apache2 ]; then
		insinto "${APACHE_MODULES_CONFDIR}"
		doins "${FILESDIR}/70_mod_php${PHP_MV}.conf"
	fi
}

pkg_postinst() {
	if use apache2; then
		# Output some info to the user.
		APACHE2_MOD_DEFINE=PHP${PHP_MV} \
		APACHE2_MOD_CONF=70_mod_php${PHP_MV} \
			apache-module_pkg_postinst
	fi

	# eselect this version of PHP, if no other is installed.
	for sapi in ${SAPIS}; do
		use ${sapi} || continue

		local ci=$(eselect php show ${sapi})
		if [ -z ${ci} ]; then
			eselect php set ${sapi} php${SLOT}
			einfo "Switched ${sapi} to use php:${SLOT}"
			einfo
		elif [ ${ci} != php${SLOT} ]; then
			elog "To switch ${sapi} to use php:${SLOT}, run"
			elog "    eselect php set ${sapi} php${SLOT}"
			elog
		fi
	done

	elog "Make sure that PHP_TARGETS in /etc/make.conf includes php${SLOT/./-} in order"
	elog "to compile extensions for the ${SLOT} ABI"
	elog

	if use curl; then
		ewarn 'Please be aware that cURL can allow the bypass of open_basedir restrictions.'
		ewarn 'This can be a security risk!'
		ewarn
	fi
}

src_test() {
	einfo ">>> Test phase [test]: ${CATEGORY}/${PF}"
	if ! emake -j1 test; then
		local cmd
		hasq test ${FEATURES} && cmd=die || cmd=eerror
		${cmd} 'Make test failed. See above for details.'
	fi
}
