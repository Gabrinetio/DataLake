#!/usr/bin/env bash
set -euo pipefail

# generate_dns_zone.sh
# Generates a BIND zone file from infra/dns/hosts.map.
# Usage: generate_dns_zone.sh [--apply] [--zone-file /path/to/zone-file] [--dns-server root@192.168.4.30]

MAP_FILE="$(dirname "$0")/../dns/hosts.map"
ZONE_FILE="/tmp/db.gti.local.zone"
DNS_SERVER="root@192.168.4.30"
APPLY=0

show_help() {
  cat <<EOF
Usage: $0 [--apply] [--zone-file <path>] [--dns-server <user@host>]
Generates a BIND zone file from hosts.map; --apply pushes it to DNS server and reloads bind (needs ssh access).
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --apply) APPLY=1; shift;;
    --zone-file) ZONE_FILE="$2"; shift 2;;
    --dns-server) DNS_SERVER="$2"; shift 2;;
    -h|--help) show_help; exit 0;;
    *) echo "Unknown arg: $1"; show_help; exit 1;;
  esac
done

if [[ ! -f "$MAP_FILE" ]]; then
  echo "Missing map file at $MAP_FILE"; exit 2
fi

TTL=3600
SOA_SERIAL=$(date +%Y%m%d%H)
HOSTNAME="gti.local"

cat > "$ZONE_FILE" <<EOF
$TTL ; default TTL
@ IN SOA ns.gti.local. admin.gti.local. (
    $SOA_SERIAL ; serial
    3600 ; refresh
    900 ; retry
    604800 ; expire
    86400 ; minimum
)
; Name servers
@ IN NS ns.gti.local.
ns IN A 192.168.4.30

; Hosts
EOF

while read -r ip host alias; do
  [[ -z "$ip" || "$ip" =~ ^# ]] && continue
  echo "$host IN A $ip" >> "$ZONE_FILE"
  if [[ -n "$alias" ]]; then
    echo "$alias IN CNAME $host" >> "$ZONE_FILE"
  fi
done < "$MAP_FILE"

echo "Zone file generated: $ZONE_FILE"

if [[ $APPLY -eq 1 ]]; then
  echo "Pushing zone file to $DNS_SERVER:/etc/bind/zones/db.gti.local"
  scp "$ZONE_FILE" "$DNS_SERVER:/etc/bind/zones/db.gti.local"
  echo "Reloading BIND on $DNS_SERVER"
  ssh "$DNS_SERVER" "rndc reload || systemctl reload bind9 || true"
  echo "Zone applied (reload attempted)."
fi

echo "Done. Dry-run only by default; use --apply to push changes."
