#!/bin/sh

# Script for enabling automatic login
# Copyright (C) 2016 Karlson2k (Evgeny Grin)
#
# You can run, copy, modify, publish and do whatever you want with this
# script as long as this message and copyright string above are preserved.
# You are also explicitly allowed to reuse this script under any LGPL or
# GPL license or under any BSD-style license.
#
# This script will enable automatic login which is useful for virtual
# machines used for development and testing, without sensitive
# information. Of course it can be used for real machines, but it isn't
# good idea in general.
# Currently only LXDM display manager is supported.
# Quick run:
# wget https://git.io/vwPYw -O set-al.sh && chmod +x set-al.sh && ./set-al.sh
#
# Latest version:
# https://raw.githubusercontent.com/Karlson2k/k2k-vbox-tools/master/set-autologin.sh
#
# Version 0.4.0

if [ "$1" != "--no-bash" ] && which bash 1>/dev/null 2>/dev/null; then
  bash "$0" --no-bash "$@"
  exit $?
fi

unset echo_n || exit 5
echo -n '' 1>/dev/null 2>/dev/null && echo_n='echo -n'
[ -z "$echo_n" ] && echo_n='echo'

alname=$SUDO_USER

[ -n $alname ] || alname=$(id -u -n 2>/dev/null) || \
  alname=$(whoami 2>/dev/null) || \
  alname=$LOGNAME || unset alname

[ -z $alname ] && alname=$USER
[ -z $alname ] && alname=$USERNAME

if [ -z $alname ]; then
  echo 'Cannot detect current user name. Exiting.' 1>&2
  exit 2
fi

if [ "$alname" = "root" ]; then
  echo 'Automatic login for "root" is not supported' 1>&2
  exit 3
fi

$echo_n "Use \"$alname\" for automatic login? [y/n]"
read -n 1 answ 2>/dev/null || read answ || exit 5
echo ''
if [ "$answ" != "y" ] && [ "$answ" != "Y" ]; then
  echo 'Exiting.'
  exit 5
fi

tmp_file="$(mktemp -t autologin-tmp.XXXXXX)" || exit 2
[ "$(id -u)" != "0" ] && echo 'Superuser rights are required, you may be asked for password.'
sudo -s <<_SUDOEND_
if [ -f /etc/lxdm/lxdm.conf ]; then
  echo 'Found LXDM configuration.'
  modify_ok='no' || exit 5
  if egrep -q -e '^#?autologin=' /etc/lxdm/lxdm.conf; then
    unset oldalname || exit 5
    if oldalname=\$(sed -n "s/^autologin=\(.*\)$/\1/1p" /etc/lxdm/lxdm.conf) && \
         [ -n "\$oldalname" ] ; then
      echo "LXDM was configured to automatically login user \"\$oldalname\"."
    fi
    if [ "\$oldalname" = "$alname" ]; then
      echo 'Configuration will be updated anyway just in case.'
    fi
    sed -e "s/^#*autologin=.*$/autologin=$alname/" /etc/lxdm/lxdm.conf > "$tmp_file" && \
      modify_ok='yes'
  else
	if egrep -q -e '^\[base\]$' /etc/lxdm/lxdm.conf ; then
	  sed -e '/^\[base\]\$/a\
autologin=$alname
'        /etc/lxdm/lxdm.conf > "$tmp_file" && \
        modify_ok='yes'
	else
	  cat /etc/lxdm/lxdm.conf > "$tmp_file" && \
        echo "[base]
autologin=$alname
" >> "$tmp_file" && \
        modify_ok='yes'
	fi
  fi
  if [ "\$modify_ok" = "yes" ] && \
      install -m 0600 "$tmp_file" /etc/lxdm/lxdm.conf ; then
    echo "LXDM configuration is updated to automatically login user \"$alname\"."
  else
    echo 'Failed to modify LXDM configuration' 1>&2
  fi
fi
# Empty temp file
truncate -s 0 "$tmp_file" 2>/dev/null|| : > "$tmp_file"
rm -f "$tmp_file"
_SUDOEND_
