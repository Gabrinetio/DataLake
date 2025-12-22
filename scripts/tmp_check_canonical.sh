#!/usr/bin/env bash
set -euo pipefail

CTS="107 108 109 115 116 117 118"
PUB="/tmp/ct_pub.pub"

if [[ ! -f "$PUB" ]]; then
  echo "Chave publica nao encontrada em $PUB" >&2
  exit 2
fi

for ct in $CTS; do
  if pct exec $ct -- grep -xF "$(cat $PUB)" /home/datalake/.ssh/authorized_keys >/dev/null 2>&1; then
    echo "CT $ct presente"
  else
    echo "CT $ct ausente"
  fi
done
