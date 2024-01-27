**Raf’s** Portage overlay

## Introduction

This is my [Portage](https://wiki.gentoo.org/wiki/Portage) overlay. I maintain
it for my computers and my personal needs, and ebuilds in here come an go as my
computers change and my needs evolve.

I run Gentoo Linux on all my computers, but this overlay should work for any
distribution that uses Portage and ebuilds.

Some ebuilds are original to this repo; some others are borrowed from others
and modified as needed, retaining any original copyright assignment.

## Installation (quick)
```
wget -O- 'https://raw.githubusercontent.com/raffaellod/gentoo-overlay-raf/master/install.sh' | sudo -s
```

## Installation (manual)

You’ll probably need to use `sudo` for all the following steps.

1. Create a new repos.conf file, such as `/etc/portage/repos.conf/raf.conf` , then
write into it:
```
[raf]
priority = 100
location = /var/db/repos/raf
sync-type = git
sync-uri = https://github.com/raffaellod/gentoo-overlay-raf.git
```
2. Then you can get an initial copy of this repo:
```
emaint sync -r raf
```

## Usage

Once installed as indicated above, running `emerge --sync` will keep your copy
of the overlay up to date. Any new ebuilds for installed packages could then be
installed with e.g. `emerge -uDU @world` as usual.

## Keywording policy

Generally, when I add a new ebuild, it gets keyworded unstable, and only for
architectures on which I actually install it.

When I bump a package, I add a new latest unstable ebuild, and if I’ve used the
former latest ebuild sufficiently, I update that to mark it as stable.

## Contributing

If you have anything to contribute, please feel free to open a pull request on
GitHub.

---
Copyright 2024 Raffaello D. Di Napoli

Distributed under the terms of the GNU General Public License v2

Copyright other authors; see individual files for copyright assignment.
