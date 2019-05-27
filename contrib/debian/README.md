
Debian
====================
This directory contains files used to package exord/exor-qt
for Debian-based Linux systems. If you compile exord/exor-qt yourself, there are some useful files here.

## exor: URI support ##


exor-qt.desktop  (Gnome / Open Desktop)
To install:

	sudo desktop-file-install exor-qt.desktop
	sudo update-desktop-database

If you build yourself, you will either need to modify the paths in
the .desktop file or copy or symlink your exorqt binary to `/usr/bin`
and the `../../share/pixmaps/exor128.png` to `/usr/share/pixmaps`

exor-qt.protocol (KDE)

