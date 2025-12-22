#!/usr/bin/env bash
set -euo pipefail

# Instala curl em um CT via Proxmox pct exec
# Uso: ct_install_curl.sh --proxmox root@192.168.4.25 --ct 116

show_help() {
  cat <<EOF
Usage: $0 --proxmox <proxmox_host> --ct <ct_id>
Instala curl no CT via pct exec (deb/ubuntu assume apt-get)
EOF
}

PROXMOX=""
CT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --proxmox) PROXMOX="$2"; shift 2;;
    --ct) CT="$2"; shift 2;;
    -h|--help) show_help; exit 0;;
    *) echo "Unknown arg: $1"; show_help; exit 1;;
  esac
done

if [[ -z "$PROXMOX" || -z "$CT" ]]; then
  show_help; exit 1
fi

echo "Instalando curl no CT $CT via $PROXMOX"
ssh "$PROXMOX" "pct exec $CT -- bash -lc 'if command -v curl >/dev/null 2>&1; then echo curl_installed; elif command -v apt-get >/dev/null 2>&1; then apt-get update && apt-get install -y curl; elif command -v yum >/dev/null 2>&1; then yum install -y curl; elif command -v apk >/dev/null 2>&1; then apk add --no-cache curl; else echo "No recognized package manager to install curl"; fi'"

echo "Instalacao finalizada (ou já estava instalado)."
