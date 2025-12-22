#!/usr/bin/env bash
set -euo pipefail

# Remove static gti.local host entries from containers and set DNS resolver to 192.168.4.30
# Usage: remove_hosts_and_set_dns.sh --proxmox root@192.168.4.25 --cts "107 108 109 111 115 116 117 118" [--dns 192.168.4.30] [--dry-run]

PROXMOX=""
LOCAL_MODE=0
CTS=""
DNS="192.168.4.30"
DRY_RUN=0

show_help() {
  cat <<EOF
Usage: $0 --proxmox <root@proxmox> --cts "<ct list>" [--dns <nameserver>] [--dry-run]
Removes lines containing '.gti.local' in /etc/hosts for each CT and sets the CT's nameserver to the provided IP (default 192.168.4.30).
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --proxmox) PROXMOX="$2"; shift 2;;
    --local) LOCAL_MODE=1; shift;;
    --cts) CTS="$2"; shift 2;;
    --dns) DNS="$2"; shift 2;;
    --dry-run) DRY_RUN=1; shift;;
    -h|--help) show_help; exit 0;;
    *) echo "Unknown arg: $1"; show_help; exit 1;;
  esac
done

if [[ -z "$CTS" ]]; then
  show_help; exit 1
fi

if [[ "$LOCAL_MODE" -eq 1 ]]; then
  PROXMOX="root@127.0.0.1"
fi

for ct in $CTS; do
  echo "Processing CT $ct..."
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "  Dry-run: would remove lines with '.gti.local' from /etc/hosts in CT $ct"
    echo "  Dry-run: would set nameserver for CT $ct to $DNS and searchdomain gti.local"
    echo "  Current /etc/hosts preview:"
    ssh "$PROXMOX" "pct exec $ct -- grep -E '\.gti\.local' /etc/hosts || true"
    echo "  Current /etc/resolv.conf preview:"
    ssh "$PROXMOX" "pct exec $ct -- cat /etc/resolv.conf || true"
    continue
  fi

  # Remove lines containing .gti.local from /etc/hosts inside the CT using a safer approach
  ssh "$PROXMOX" "pct exec $ct -- sed -i '/\\.gti\\.local/d' /etc/hosts || true"

  # Set nameserver and searchdomain via pct set (Proxmox) for persistence
  ssh "$PROXMOX" "pct set $ct --nameserver $DNS --searchdomain gti.local || true"

  # Quick validation
  echo "  After changes: grep .gti.local in /etc/hosts (should be empty)"
  ssh "$PROXMOX" "pct exec $ct -- grep -E '\\.gti\\.local' /etc/hosts || true"
  echo "  /etc/resolv.conf now:" 
  ssh "$PROXMOX" "pct exec $ct -- cat /etc/resolv.conf || true"
done

echo "All CTs processed. If any service required static /etc/hosts fallback, set USE_STATIC_HOSTS=1 on provisioning scripts."
