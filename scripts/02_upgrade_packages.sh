#!/bin/sh

# This upgrades `pkg` only. Ignore Lua errors.
pkg upgrade -yf || echo "ignore lua error"

# The previous `pkg ugprade` somehow removes the df-latest.conf.
cp /usr/local/etc/pkg/repos/df-latest.conf.sample /usr/local/etc/pkg/repos/df-latest.conf

# Update again
pkg upgrade -yf || exit 1

# Cleanup
rm -f /usr/local/etc/pkg.conf
