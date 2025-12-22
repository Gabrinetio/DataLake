#!/usr/bin/env bash
set -euo pipefail

FILE="/etc/nginx/sites-available/gitea"
BACKUP="/root/gitea_nginx.conf.bak.$(date -u +%Y%m%d%H%M%S)"

echo "[fix_gitex] criando backup: $BACKUP"
cp -a "$FILE" "$BACKUP"

echo "[fix_gitex] aplicando substituição upstream unix socket -> 127.0.0.1:3000"
# Replace upstream gitea block safely using awk (avoids complex quoting)
awk 'BEGIN{inside=0} /upstream[[:space:]]+gitea[[:space:]]*\{/{print "upstream gitea {"; print "    server 127.0.0.1:3000;"; print "}"; inside=1; next} /\}/ && inside {inside=0; next} { if(!inside) print }' "$FILE" > /tmp/gitea.conf.new
mv /tmp/gitea.conf.new "$FILE"

echo "[fix_gitex] testando configuração do nginx"
if nginx -t; then
  echo "[fix_gitex] teste OK, recarregando nginx"
  systemctl reload nginx
  echo "[fix_gitex] nginx recarregado"
else
  echo "[fix_gitex] teste nginx falhou, restaurando backup"
  cp -a "$BACKUP" "$FILE"
  exit 2
fi

echo "[fix_gitex] tarefa concluída"
exit 0
