#!/usr/bin/env bash
set -euo pipefail

# Gera um novo par de chave canônica local (não comitar a privada).
# Uso:
#   ./scripts/generate_canonical_key.sh
#   OUT=/caminho/para/ct_datalake_id_ed25519 ./scripts/generate_canonical_key.sh

OUT=${OUT:-$HOME/.ssh/ct_datalake_id_ed25519}
COMMENT=${COMMENT:-datalake@data-project}
FORCE=${FORCE:-0}

mkdir -p "$(dirname "$OUT")"

if [ -f "$OUT" ] && [ "$FORCE" != "1" ]; then
  echo "Arquivo já existe: $OUT (use FORCE=1 para sobrescrever)" >&2
  exit 1
fi

ssh-keygen -t ed25519 -a 100 -f "$OUT" -N "" -C "$COMMENT"
cout="${OUT}.pub"
echo "Chave privada: $OUT"
echo "Chave pública: $cout"

chmod 600 "$OUT"
chmod 644 "$cout" || true

echo "Opcional: adicione ao ssh-agent"
if command -v ssh-add >/dev/null 2>&1; then
  ssh-add "$OUT" || true
fi

cat <<EOF
Próximos passos sugeridos:
- Registrar a pública no Gitea: ./scripts/gitea_add_user_key.sh --token "$GITEA_TOKEN" --title "ct-datalake" --key-file $cout
- Aplicar nos CTs (authorized_keys): reutilize scripts/enforce_canonical_ssh_key.sh ou o loop via Proxmox.
- Não comitar a chave privada em hipótese alguma.
EOF
