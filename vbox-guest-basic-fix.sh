#!/bin/sh

# Script for basic fixing installed vbox guest additions
# Copyright (C) 2016 Karlson2k (Evgeny Grin)
#
# You can run, copy, modify, publish and do whatever you want with this
# script as long as this message and copyright string above are preserved.
# You are also explicitly allowed to reuse this script under any LGPL or
# GPL license or under any BSD-style license.
#
# This script is usefull for "void Linux" where virtualbox guest additions
# are not automatically started if additons were installed from repo.
# May be you will find that it's useful on other GNU/Linux distribution.
# Quick run:
# wget https://git.io/vw6qy -O vb-fix.sh && chmod 0755 vb-fix.sh && ./vb-fix.sh
#
# Latest version:
# https://raw.githubusercontent.com/Karlson2k/k2k-vbox-tools/master/vbox-guest-basic-fix.sh
#
# Version 0.6.0

print_start_all_replacement () {
cat <<__EOF__
for i in \$HOME/.vboxclient-*.pid; do
    test -w \$i || rm -f \$i
done
if ! test -c /dev/vboxguest 2>/dev/null; then
   notify-send "VBoxClient: the VirtualBox kernel service is not running.  Exiting."
elif test -z "\${SSH_CONNECTION}"; then
  /usr/bin/VBoxClient --clipboard
  /usr/bin/VBoxClient --checkhostversion
  /usr/bin/VBoxClient --display
  /usr/bin/VBoxClient --seamless
  /usr/bin/VBoxClient --draganddrop
fi
__EOF__
}

print_vbclient_desktp_replacement () {
cat <<__EOF__
[Desktop Entry]
Type=Application
Encoding=UTF-8
Version=1.0
Name=vboxclient
Comment=VirtualBox User Session Services
Exec=/usr/bin/VBoxClient-all
X-GNOME-Autostart-enabled=true
X-KDE-autostart-after=panel
__EOF__
}

echo 'Downloading latest 98vboxadd-xclient...'
if wget --version 2>/dev/null && \
      wget http://virtualbox.org/svn/vbox/trunk/src/VBox/Additions/x11/Installer/98vboxadd-xclient -O /tmp/VBoxClient-all; then
  echo 'Download completed.'
else
  echo 'Download failed, using local substituion.'
  print_start_all_replacement > /tmp/VBoxClient-all || exit 2
fi

echo 'Installing (with superuser rights) 98vboxadd-xclient as VBoxClient-all...'
sudo install -m 0755 /tmp/VBoxClient-all /usr/bin || exit 4
rm -f /tmp/VBoxClient-all

if [ -f /etc/xdg/autostart/vboxclient.desktop ]; then
  cp /etc/xdg/autostart/vboxclient.desktop /tmp/ &&
    echo 'Using installed vboxclient.desktop'
fi

if ! [ -f /tmp/vboxclient.desktop ]; then
  print_vbclient_desktp_replacement > /tmp/vboxclient.desktop || exit 5
  echo 'Using local substituion for vboxclient.desktop.'
fi

echo 'Configuring (with superuser rights) for autostart...'
sudo install -m 0644 /tmp/vboxclient.desktop /usr/share/xsessions/ || exit 6
rm -f /tmp/vboxclient.desktop
echo 'Done'

echo 'Configuring (with superuser rights) for redundant autostart...'
sudo install -m 0644 -T /usr/bin/VBoxClient-all /etc/X11/xinit/xinitrc.d/98-VBoxClient-all.sh || exit 6
echo 'Done'

exit 0