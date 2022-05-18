# Copyright 1999-2011 Gentoo Foundation
# Copyright 2012, 2022 Raffaello D. Di Napoli <rafdev@dinapo.li>
# Distributed under the terms of the GNU General Public License v2

EAPI=6

DESCRIPTION='Museum version of the PHP language runtime engine.'
HOMEPAGE='http://php.net/'
LICENSE=PHP-3

RESTRICT='mirror'
KEYWORDS='alpha amd64 arm hppa ia64 ppc ppc64 s390 sh sparc x86'
SLOT=5.2
PHP_MV=${PV%%.*}

SRC_URI="https://museum.php.net/php5/${P}.tar.bz2"

SAPIS="cli cgi embed apache2"
CGI_SAPI_USE="discard-path force-cgi-redirect"
EXTENSIONS_USE="
	berkdb bzip2
	cdb cjk crypt curl curlwrappers
	exif
	fdftk filter firebird
	gd gd-external gdbm gmp
	iconv imap iodbc ipv6
	jpeg
	kerberos kolab
	ldap ldap-sasl libedit
	mhash mssql mysql mysqli
	ncurses nls
	odbc
	pcre pdo png postgres
	qdbm
	readline recode
	sharedmem simplexml snmp soap spell sqlite ssl sybase-ct sysvipc
	tidy truetype
	unicode
	wddx
	xml xmlreader xmlwriter xmlrpc xpm xsl
	zip zlib
"
IUSE="
	branding debug doc minimal pic sharedext threads
	+${SAPIS} ${CGI_SAPI_USE} ${EXTENSIONS_USE}
"
REQUIRED_USE="|| ( ${SAPIS} )"

# Extensions that pull in gd (internal) will also pull in whatever gd needs
# to support them; the same goes for other libs.
RDEPEND="
	>=app-eselect/eselect-php-0.6.2
	virtual/mta

	apache2? ( >=www-servers/apache-2[threads=] )

	berkdb? ( =sys-libs/db-4* )
	bzip2? ( app-arch/bzip2 )
	cdb? ( || ( dev-db/cdb dev-db/tinycdb ) )
	crypt? ( >=dev-libs/libmcrypt-2.4 )
	curl? ( >=net-misc/curl-7.10.5 )
	exif? ( !gd-external? ( media-libs/libpng app-arch/bzip2
		sys-libs/zlib ) )
	fdftk? ( app-text/fdftk )
	firebird? ( dev-db/firebird )
	gd? ( virtual/jpeg media-libs/libpng sys-libs/zlib )
	gd-external? ( media-libs/gd )
	gdbm? ( !qdbm? ( >=sys-libs/gdbm-1.8.0 ) )
	gmp? ( >=dev-libs/gmp-4.1.2 )
	iconv? ( virtual/libiconv )
	imap? ( virtual/imap-c-client[ssl=] )
	iodbc? ( dev-db/libiodbc )
	jpeg? ( !gd-external? ( media-libs/libpng app-arch/bzip2 sys-libs/zlib
		 virtual/jpeg ) )
	kerberos? ( virtual/krb5 )
	kolab? ( >=net-libs/c-client-2004g-r1 )
	ldap? ( >=net-nds/openldap-1.2.11 )
	ldap-sasl? ( dev-libs/cyrus-sasl >=net-nds/openldap-1.2.11 )
	libedit? ( || ( sys-freebsd/freebsd-lib dev-libs/libedit ) )
	mhash? ( app-crypt/mhash )
	!minimal? ( !dev-php${PHP_MV}/pecl-json )
	mssql? ( dev-db/freetds[mssql] )
	mysql? ( virtual/mysql )
	mysqli? ( >=virtual/mysql-4.1 )
	ncurses? ( sys-libs/ncurses )
	nls? ( sys-devel/gettext )
	odbc? ( >=dev-db/unixODBC-1.8.13 )
	pcre? ( >=dev-libs/libpcre-7.9[unicode] )
	png? ( !gd-external? ( media-libs/libpng app-arch/bzip2
		sys-libs/zlib ) )
	postgres? ( dev-db/postgresql-base )
	qdbm? ( dev-db/qdbm )
	readline? ( !libedit? ( sys-libs/readline ) )
	recode? ( app-text/recode )
	sharedmem? ( !threads? ( dev-libs/mm ) )
	simplexml? ( >=dev-libs/libxml2-2.6.8 )
	snmp? ( >=net-analyzer/net-snmp-5.2 )
	soap? ( >=dev-libs/libxml2-2.6.8 )
	spell? ( >=app-text/aspell-0.50 )
	sqlite? ( =dev-db/sqlite-2* pdo? ( =dev-db/sqlite-3* ) )
	ssl? ( >=dev-libs/openssl-0.9.7 )
	sybase-ct? ( dev-db/freetds )
	tidy? ( app-text/htmltidy )
	truetype? ( !gd-external? ( virtual/jpeg media-libs/libpng
		sys-libs/zlib =media-libs/freetype-2*
		>=media-libs/t1lib-5.0.0 ) )
	wddx? ( >=dev-libs/libxml2-2.6.8 )
	xml? ( >=dev-libs/libxml2-2.6.8 )
	xmlrpc? ( >=dev-libs/libxml2-2.6.8 virtual/libiconv )
	xmlreader? ( >=dev-libs/libxml2-2.6.8 )
	xmlwriter? ( >=dev-libs/libxml2-2.6.8 )
	xpm? ( !gd-external? ( media-libs/libpng app-arch/bzip2 sys-libs/zlib
		x11-libs/libXpm ) )
	xsl? ( >=dev-libs/libxml2-2.6.8 dev-libs/libxslt )
	zip? ( !dev-php${PHP_MV}/pecl-zip sys-libs/zlib )
	zlib? ( sys-libs/zlib )
"
DEPEND="
	${RDEPEND}
	sys-devel/flex
	>=sys-devel/libtool-1.5.18
	>=sys-devel/m4-1.4.3
"
PDEPEND="
	doc? ( app-doc/php-docs )
"

inherit apache-module autotools depend.apache eutils flag-o-matic libtool

want_apache

pkg_setup() {
	# Mail support
	if ! [ -x "${ROOT}/usr/sbin/sendmail" ]; then
		ewarn "You need a virtual/mta that provides a sendmail compatible binary!"
		ewarn "All major MTAs provide this, and it's usually some symlink created"
		ewarn "as '${ROOT}/usr/sbin/sendmail*'. You should also be able to use other"
		ewarn "MTAs directly, but you'll have to edit the sendmail_path directive"
		ewarn "in your php.ini for this to work."
		ewarn
	fi

	depend.apache_pkg_setup
}

src_prepare() {
	# USE=sharedmem (session/mod_mm to be exact) tries to mmap() the path:
	#   [empty session.save_path]/session_mm_[sapi][gid].sem
	# there is no easy way to avoid that, all PHP calls during install use
	# -n, so no php.ini file will be used. Only this works easily enough.
	addpredict /session_mm_cli250.sem
	addpredict /session_mm_cli0.sem

	# kolab support (support for imap annotations).
	use kolab && epatch "${FILESDIR}/${P}-imap-kolab-annotations.patch"

	epatch "${FILESDIR}/${P}-pack.patch"

	# Prevent PHP from activating the Apache config, as we will do that
	# ourselves.
	sed -i -e '
		s/-i -[Aa] -n php/-i -n php/
	' configure sapi/apache2{filter,handler}/config.m4

	if use branding; then
		# Show Gentoo as the server platform.
		sed -i -e '
			s/^\(PHP_EXTRA_VERSION="\)[^"]*\("\)/\1-gentoo\2/
			s/^\(PHP_UNAME=`uname \)-a\( | xargs`\)/\1-s -n -r -v\2/
		' configure.in || die 'Unable to brand PHP'
	fi
	if has_version app-crypt/heimdal; then
		# Support heimdal instead of mit-krb5.
		sed -i -e '
			s/gssapi_krb5/gssapi/g
			/PHP_ADD_LIBRARY(k5crypto, 1, $1)/ d
		' acinclude.m4 || die 'Failed to fix PHP for heimdal'
	fi
	if has_version '>=sys-devel/autoconf-2.64'; then
		# Bug 281697: work around divert() issues with newer autoconf.
		sed -i -re '
			s/^((m4_)?divert)[(]([0-9]*)[)]/\1(600\3)/
		' $(grep -l divert $(find . -name '*.m4') configure.in) ||
			die 'Failed to patch for recent autoconf'
	fi

	# We are heavily patching autotools base files (configure.in), so
	# let's regenerate the whole stuff now.

	# eaclocal doesn't accept --force, so we try to force re-generation
	# this way.
	rm aclocal.m4
	eautoreconf --force -W no-cross
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
	if use simplexml || use soap || use wddx || use xml ||
		use xmlrpc || use xmlreader || use xsl; then
		use_xml=true
	else
		use_xml=false
	fi

	conf=

	# Convert USE flags to configure flags (SAPI and related).
	#
	#		can_sh	USE flag	extension	external path
	#
	if use amd64; then
		# Force -fPIC on amd64, or the build will break.
		use_w	no_sh	-		pic
	else
		use_w	no_sh	pic
	fi
	use_en		no_sh	debug
	use_en		no_sh	threads		maintainer-zts

	# Convert USE flags to configure flags (extensions).
	#
	#		can_sh	USE flag	extension	external path
	#
	{ use berkdb || use cdb || use gdbm || use !minimal || use qdbm; } &&
		use_en	can_sh	-		dba
	${use_xml} &&
		use_en	can_sh	-		libxml
	{ ${use_gd} || ${use_xml} || use zlib; } &&
		use_w	no_sh	-		zlib-dir	/usr
	use_en		can_sh	!minimal	bcmath
	use_en		can_sh	!minimal	calendar
	use_en		can_sh	!minimal	ctype
	use_en		can_sh	!minimal	dbase
	use_en		can_sh	!minimal	flatfile
	use_en		can_sh	!minimal	ftp
	use_en		can_sh	!minimal	hash
	use_en		can_sh	!minimal	inifile
	use_en		can_sh	!minimal	json
	use_en		can_sh	!minimal	pcntl
	use_en		can_sh	!minimal	posix
	use_en		can_sh	!minimal	reflection
	use_en		can_sh	!minimal	session
	use_en		can_sh	!minimal	sockets
	use_en		no_sh	!minimal	spl
	use_en		can_sh	!minimal	tokenizer
	use_w		can_sh	berkdb		db4
	use_w		can_sh	bzip2		bz2
	use_w		can_sh	cdb
	use_w		can_sh	crypt		mcrypt
	use_w		can_sh	curl
	use_w		can_sh	curlwrappers
	use_w		can_sh	fdftk		fdftk		/opt/fdftk-6.0
	use_w		can_sh	filter
	use_w		can_sh	firebird	interbase	/usr
	use !qdbm &&
		use_w	can_sh	gdbm
	use_w		can_sh	gmp
	use_w		can_sh	iconv
	use_w		can_sh	imap
	use_w		can_sh	iodbc		iodbc		/usr
	use_en		can_sh	ipv6
	use_w		no_sh	kerberos	kerberos	/usr
	use_w		can_sh	ldap
	use ldap &&
		use_w	can_sh	ldap-sasl
	use_w		can_sh	libedit
	use_w		can_sh	mhash
	use_w		can_sh	mssql
	use pdo &&
		use_w	can_sh	mssql		pdo-dblib
	use_w		can_sh	mysql		mysql		/usr
	use_w		no_sh	mysql		mysql-sock	/var/run/mysqld/mysqld.sock
	use pdo &&
		use_w	can_sh	mysql		pdo-mysql	/usr
	use_w		can_sh	mysqli		mysqli		/usr/bin/mysql_config
	use_w		can_sh	ncurses
	use_w		can_sh	nls		gettext
	use_w		can_sh	odbc		unixODBC	/usr
	use pdo &&
		use_w	can_sh	odbc		pdo-odbc	unixODBC,/usr
	# For filter and zip.
	use_w		no_sh	pcre		pcre-dir	/usr
	# For pcre and spl.
	use_w		no_sh	pcre		pcre-regex	/usr
	use_en		can_sh	pdo
	use_w		can_sh	postgres	pgsql
	use pdo &&
		use_w	can_sh	postgres	pdo-pgsql
	use_w		can_sh	qdbm
	use !libedit &&
		use_w	can_sh	readline
	use_w		can_sh	recode
	use_en		can_sh	simplexml
	use !minimal &&
		use_w	can_sh	sharedmem	mm
	use !threads &&
		use_en	can_sh	sharedmem	shmop
	use_w		can_sh	snmp
	use_en		can_sh	soap
	use_w		can_sh	spell		pspell
	use_w		can_sh	sqlite		sqlite		/usr
	use pdo &&
		use_w	can_sh	sqlite		pdo-sqlite	/usr
	use_w		can_sh	ssl		openssl
	use_w		no_sh	ssl		openssl-dir	/usr
	use imap &&
		use_w	can_sh	ssl		imap-ssl
	use_w		can_sh	sybase-ct
	use_en		can_sh	sysvipc		sysvmsg
	use_en		can_sh	sysvipc		sysvsem
	use_en		can_sh	sysvipc		sysvshm
	use_w		can_sh	tidy
	use_en		can_sh	unicode		mbstring
	use sqlite &&
		use_en	can_sh	unicode		sqlite-utf8
	use_en		can_sh	wddx
	use_en		can_sh	xml
	use_en		can_sh	xml		dom
	use_en		can_sh	xmlreader
	use_en		can_sh	xmlwriter
	use_w		can_sh	xmlrpc
	use_w		can_sh	xsl
	use_en		can_sh	zip
	use_w		can_sh	zlib
	#
	# gd and gd-related extensions.
	if use gd-external; then
		use_en	no_sh	cjk		gd-jis-conv
		use_w	can_sh	-		gd		/usr
	elif ${use_gd}; then
		use_en	no_sh	cjk		gd-jis-conv
		use_en	can_sh	exif
		use_w	no_sh	jpeg		jpeg-dir	/usr
		use_w	no_sh	png		png-dir		/usr
		use_w	can_sh	truetype	freetype-dir	/usr
		use_w	can_sh	truetype	t1lib		/usr
		use_w	no_sh	xpm		xpm-dir		/usr
		# Enable gd last, so configure can pick up the previous
		# settings.
		use_w	can_sh	-		gd
	fi


	# Bug 14067. Reverse the order to fix bug 32022 and bug 12021.
	replace-cpu-flags 'k6*' i586

	local destdir=/usr/$(get_libdir)/php${SLOT}

	mkdir "${WORKDIR}/sapis-build"
	for sapi in ${SAPIS}; do
		use ${sapi} || continue

		inidir=/etc/php/${sapi}-php${SLOT}
		iniextdir=${inidir}/ext
		iniextactivedir=${inidir}/ext-active

		cp -r "${S}" "${WORKDIR}/sapis-build/${sapi}"
		cd "${WORKDIR}/sapis-build/${sapi}"
		sconf="${conf}"
		for othersapi in ${SAPIS}; do
			case ${othersapi} in
			(cli|embed)
				if [ ${sapi} = ${othersapi} ]; then
					sconf="${sconf} --enable-${othersapi}"
				else
					sconf="${sconf} --disable-${othersapi}"
				fi
				;;
			(cgi)
				if [ ${sapi} = ${othersapi} ]; then
					sconf="${sconf} --enable-cgi --enable-fastcgi"
					use discard-path &&
						sconf="${sconf} --enable-discard-path"
					use force-cgi-redirect &&
						sconf="${sconf} --enable-force-cgi-redirect"
				else
					sconf="${sconf} --disable-${othersapi}"
				fi
				;;
			(apache2)
				if [ ${sapi} = ${othersapi} ]; then
					sconf="${sconf} --with-apxs2=/usr/sbin/apxs"
				else
					sconf="${sconf} --without-apxs2"
				fi
				;;
			esac
		done

		econf \
			--prefix="${EPREFIX}${destdir}" \
			--mandir="${EPREFIX}${destdir}/man" \
			--infodir="${EPREFIX}${destdir}/info" \
			--libdir="${EPREFIX}${destdir}/lib" \
			--with-config-file-path="${EPREFIX}${inidir}" \
			--with-config-file-scan-dir="${EPREFIX}${iniextactivedir}" \
			--disable-all \
			--without-pear \
			${sconf}
	done
}

src_compile() {
	# Bug 324739: snmp seems to run during src_compile, too.
	addpredict /usr/share/snmp/mibs/.index

	for sapi in ${SAPIS} ; do
		use ${sapi} || continue

		cd "${WORKDIR}/sapis-build/${sapi}"
		emake
		mkdir -p "${WORKDIR}/sapis/${sapi}"

		local src=
		case ${sapi} in
		(cli)	src=sapi/cli/php ;;
		(cgi)	src=sapi/cgi/php-cgi ;;
		(fpm)	src=sapi/fpm/php-fpm ;;
		(embed)	src=libs/libphp${PHP_MV}.so ;;
		(apache2)
			# apache2 is a special case; the necessary files (yes,
			# multiple) are copied by make install, not by the
			# ebuild; that's the reason why apache2 has to be the
			# last in SAPIS.
			emake INSTALL_ROOT="${WORKDIR}/sapis/${sapi}/" install-sapi
			continue
			;;
		esac

		cp ${src} "${WORKDIR}/sapis/${sapi}" ||
			die "Unable to copy ${sapi} SAPI"
	done
}

src_install() {
	local destdir=/usr/$(get_libdir)/php${SLOT}

	use snmp &&
		addpredict /usr/share/snmp/mibs/.index

	# Move to the first SAPI built, and install common files from there.
	for sapi in ${SAPIS}; do
		if use ${sapi}; then
			cd "${WORKDIR}/sapis-build/${sapi}"
			break
		fi
	done

	# Makefile forgets to create this before trying to write to it.
	dodir ${destdir}/bin
	# Install PHP, without any SAPIs.
	emake INSTALL_ROOT="${D}" install-{build,headers,programs}
	PHP_EXTDIR=$("${D}/${destdir}/bin/php-config" --extension-dir) ||
		die 'Unable to determine the extensions directory'
	# Install shared extensions, if any.
	if use sharedext && [ "$(echo modules/*.so)" != 'modules/*.so' ]; then
		insinto "${PHP_EXTDIR}"
		doins modules/*.so
	fi

	# Create the directory where we'll put version-specific php scripts
	keepdir /usr/share/php${PHP_MV}

	local sapi file= sapi_list=
	for sapi in ${SAPIS}; do
		use ${sapi} || continue

		einfo "Installing SAPI: ${sapi}"
		into ${destdir}
		file=$(find "${WORKDIR}/sapis/${sapi}" -type f -print -quit)
		if [ "${file%.so}" != "${file}" ]; then 
			if [ ${sapi} = apache2 ]; then
				insinto ${destdir}/apache2
				doins "${file}"
				keepdir /usr/$(get_libdir)/apache2/modules
			else
				dolib.so "${file}"
			fi
		else
			dobin "${file}"
		fi
		sapi_install_ini ${sapi}

		# Construct correct SAPI string for php-config.
		sapi_list="${sapi_list} ${sapi}"
		[ ${sapi} = apache2 ] && sapi_list="${sapi_list}handler"
	done

	# Install env.d files.
	newenvd "${FILESDIR}/20php${PHP_MV}-envd" 20php${SLOT}
	sed -i -e "
		s|/lib/|/$(get_libdir)/|g
		s|php${PHP_MV}|php${SLOT}|g
	" "${D}/etc/env.d/20php${SLOT}"

	# Bug 278439: set php-config variable correctly.
	sed -i -e "
		s/^\(php_sapis=\)\".*\"$/\1\"${sapi_list# }\"/
	" "${D}/usr/$(get_libdir)/php${SLOT}/bin/php-config"

	# Install example PHP ini files into /usr/share/php.
	if [ -f php.ini-development ]; then
		dodoc php.ini-development
		dodoc php.ini-production
	else
		newdoc php.ini-dist php.ini-development
		newdoc php.ini-recommended php.ini-production
	fi
}

sapi_install_ini() {
	local sapi=${1}
	cd "${WORKDIR}/sapis-build/${sapi}"

	# work out where we are installing the ini file
	inidir=/etc/php/${sapi}-php${SLOT}
	iniextdir=${inidir}/ext
	iniextactivedir=${inidir}/ext-active

	sed -e '
		# Set the extension directory.
		s|^extension_dir .*|extension_dir = '"${PHP_EXTDIR}"'|

		# Set the include path to point to where we want to find PEAR
		# packages.
		s|^;include_path = ".:/php/includes".*|include_path = ".:/usr/share/php'${PHP_MV}':/usr/share/php"|

		# Bug 332763: default allow_url_open to off.
		s|^allow_url_fopen .*|allow_url_fopen = Off|

		# Bug 300695: default expose_php to off.
		s|^expose_php .*|expose_php = Off|

		# Bug 282768: default session.save_path to /tmp.
		s|^;session.save_path .*|session.save_path = "/tmp"|
	' <php.ini-dist >php.ini-${sapi}

	dodir "${inidir}"
	insinto "${inidir}"
	newins php.ini-${sapi} php.ini

	elog "Installing php.ini for ${sapi} into ${inidir}"
	elog

	dodir ${iniextdir}
	dodir ${iniextactivedir}

	if use sharedext; then
		# Install any extensions built as shared objects.
		find "${D}/${PHP_EXTDIR}" -name '*.so' -printf '%f\n' |
		while read ext; do
			ini=${ext%.so}.ini
			echo "extension=${ext}" >>"${D}/${iniextdir}/${ini}"
			dosym "${iniextdir}/${ini}" "${iniextactivedir}/${ini}"
		done
	fi

	# SAPI-specific handling
	if [ ${sapi} = apache2 ]; then
		insinto "${APACHE_MODULES_CONFDIR}"
		doins "${FILESDIR}/70_mod_php${PHP_MV}.conf"
	elif [ ${sapi} = fpm ]; then
		[ -n ${PHP_FPM_INIT_VER} ] || PHP_FPM_INIT_VER=3
		[ -n ${PHP_FPM_CONF_VER} ] || PHP_FPM_CONF_VER=0
		einfo "Installing FPM CGI config file php-fpm.conf"
		insinto ${inidir}
		newins "${FILESDIR}/php-fpm-r${PHP_FPM_CONF_VER}.conf" php-fpm.conf
		dodir /etc/init.d
		insinto /etc/init.d
		newinitd "${FILESDIR}/php-fpm-r${PHP_FPM_INIT_VER}.init" php-fpm

		# Bug 359906: remove bogus /etc/php-fpm.conf.default.
		rm -f "${D}/etc/php-fpm.conf.default"
	fi
}

src_test() {
	vecho ">>> Test phase [test]: ${CATEGORY}/${PF}"

	if [ ! -x "${WORKDIR}/sapis/cli/php" ]; then
		ewarn 'Test phase requires USE=cli, skipping'
		return
	fi

	export TEST_PHP_EXECUTABLE="${WORKDIR}/sapis/cli/php"
	[ -x "${WORKDIR}/sapis/cgi/php-cgi" ] &&
		export TEST_PHP_CGI_EXECUTABLE="${WORKDIR}/sapis/cgi/php-cgi"

	REPORT_EXIT_STATUS=1 \
		"${TEST_PHP_EXECUTABLE}" \
		-n -d "session.save_path=${T}" \
		"${WORKDIR}/sapis-build/cli/run-tests.php" \
		-n -q -d "session.save_path=${T}"

	local failed="$(find -name '*.out')"
	if [ -n ${failed} ]; then
		ewarn 'The following test cases failed unexpectedly:'
		for name in ${failed}; do
			ewarn "  ${name%.out}"
		done
	else
		einfo 'No unexpected test failures, all fine'
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
		use ${sapi} && [ ${sapi} != embed ] || continue

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
	if ! use readline && use cli; then
		ewarn "Note that in order to use php interactivly, you need to enable"
		ewarn "the readline USE flag or php -a will hang"
	fi
}
