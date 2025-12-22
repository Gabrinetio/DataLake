#!/usr/bin/env bash
set -euo pipefail

CTS="107 108 109 111 115 116 117 118"
DNS="192.168.4.30"

for ct in $CTS; do
  echo "Removing .gti.local entries from CT $ct using pct exec"
  pct exec $ct -- sed -i '/\\.gti\\.local/d' /etc/hosts || true
  echo "Setting DNS: $DNS for CT $ct"
  pct set $ct --nameserver $DNS --searchdomain gti.local || true
  echo "Post-change: grep on /etc/hosts"
  pct exec $ct -- grep -E '\\.gti\\.local' /etc/hosts || true
  echo "resolv.conf:"
  pct exec $ct -- cat /etc/resolv.conf || true
done

echo "Done."
