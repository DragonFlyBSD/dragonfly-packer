#!/bin/sh

pkg install -y sudo

# Configure sudoers
#
mkdir -p /usr/local/etc/sudoers.d
echo '%wheel ALL=(ALL) NOPASSWD: ALL' > /usr/local/etc/sudoers.d/wheel
chmod 440 /usr/local/etc/sudoers.d/wheel
