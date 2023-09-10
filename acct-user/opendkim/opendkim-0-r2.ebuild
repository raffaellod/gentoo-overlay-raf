# Copyright 2019-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2
# From https://wiki.gentoo.org/wiki/OpenDKIM

EAPI=7

inherit acct-user

DESCRIPTION="User for OpenDKIM"

ACCT_USER_ID=334
# dkimsocket goes first, to make it the primary group
ACCT_USER_GROUPS=( dkimsocket opendkim )

acct-user_add_deps
