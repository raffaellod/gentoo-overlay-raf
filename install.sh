#!/bin/sh -eu
# -*- coding: utf-8; mode: sh; tab-width: 3; indent-tabs-mode: nil -*-
#
# Copyright 2024 Raffaello D. Di Napoli <rafdev@dinapo.li>
# Distributed under the terms of the GNU General Public License v2

# May be overridden before calling this script.
: "${ROOT:=}"

github_repo=raffaellod/gentoo-overlay-raf
overlay_name=raf
overlay_name_pretty='Raf’s'

echo "Installing ${github_repo#*/} (“${overlay_name_pretty} Portage overlay”) on this computer" >&2
if ! [ -d "${ROOT}/etc/portage" ]; then
   echo "Could not find directory ${ROOT}/etc/portage . Is Portage installed?" >&2
   exit 10
fi

repos_conf="${ROOT}/etc/portage/repos.conf"
if [ -d "${repos_conf}" ]; then
   repo_conf="${repos_conf}/${overlay_name}.conf"
elif [ -f "${repos_conf}" ]; then
   repo_conf="${repos_conf}"
elif [ -e "${repos_conf}" ]; then
   echo "It looks like ${repos_conf} is neither a directory nor a file; cannot proceed." >&2
   exit 20
else
   if ! mkdir "${repos_conf}"; then
      echo "Could not create file in repos.conf; please make sure permissions are set correctly." >&2
      exit 21
   fi
   repo_conf="${repos_conf}/${overlay_name}.conf"
fi

echo "Writing to ${repo_conf}" >&2
cat >>"${repo_conf}" <<-EOF
	[${overlay_name}]
	priority = 100
	location = ${ROOT}/var/db/repos/${overlay_name}
	sync-type = git
	sync-uri = https://github.com/${github_repo}.git
EOF

echo "Performing initial synchronization of the new repo" >&2
if ! emaint sync -r "${overlay_name}"; then
   echo "emaint failed: ${?}" >&2
   exit 30
fi

echo "Installation of ${overlay_name_pretty} Portage overlay complete!" >&2
