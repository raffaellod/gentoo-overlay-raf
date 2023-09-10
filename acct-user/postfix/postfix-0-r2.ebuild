# Copyright 2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2
# From https://wiki.gentoo.org/wiki/OpenDKIM

EAPI=7

inherit acct-user

DESCRIPTION="user for postfix daemon"
ACCT_USER_ID=207
ACCT_USER_GROUPS=( postfix mail dkimsocket )

acct-user_add_deps
