#!/usr/bin/env bash
set -euo pipefail

HOSTS="${HOSTS:-}"
KEY_PATH="${KEY_PATH:-scripts/key/ct_datalake_id_ed25519}"
SSH_USER="${SSH_USER:-datalake}"
SSH_OPTS="${SSH_OPTS:-}" # ex.: -o StrictHostKeyChecking=no
TIMEOUT="${TIMEOUT:-5}"
LOG_PATH="${LOG_PATH:-artifacts/logs/test_canonical_ssh.log}"

usage() {
  cat <<'EOF'
Uso: test_canonical_ssh.sh --hosts "host1 host2" [--key scripts/key/ct_datalake_id_ed25519] [--user datalake] [--ssh-opts "-o StrictHostKeyChecking=no"] [--timeout 5]
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --hosts) HOSTS="$2"; shift 2 ;;
    --key) KEY_PATH="$2"; shift 2 ;;
    --user) SSH_USER="$2"; shift 2 ;;
    --ssh-opts) SSH_OPTS="$2"; shift 2 ;;
    --timeout) TIMEOUT="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Parametro desconhecido: $1" >&2; usage; exit 1 ;;
  esac
done

if [[ -z "$HOSTS" ]]; then
  echo "Defina --hosts (lista separada por espaco) ou variavel HOSTS." >&2
  usage
  exit 1
fi

if [[ ! -f "$KEY_PATH" ]]; then
  echo "Chave nao encontrada: $KEY_PATH" >&2
  exit 1
fi

mkdir -p "$(dirname "$LOG_PATH")"
echo "# Teste iniciado em $(date -Iseconds)" > "$LOG_PATH"

ok=0
fail=0

for h in $HOSTS; do
  echo "==== Testando $h ====" | tee -a "$LOG_PATH"

  # DNS/host resolucao
  if command -v getent >/dev/null 2>&1; then
    getent hosts "$h" | tee -a "$LOG_PATH" || echo "(resolucao falhou para $h)" | tee -a "$LOG_PATH"
  else
    echo "(getent indisponivel, pulando resolucao explicita)" | tee -a "$LOG_PATH"
  fi

  # Verificar porta 22
  if command -v nc >/dev/null 2>&1; then
    if nc -z -w "$TIMEOUT" "$h" 22 >/dev/null 2>&1; then
      echo "porta 22 acessivel" | tee -a "$LOG_PATH"
    else
      echo "porta 22 inacessivel (nc)" | tee -a "$LOG_PATH"
    fi
  else
    echo "(nc indisponivel, pulando teste de porta)" | tee -a "$LOG_PATH"
  fi

  # Ping para diagnosticar rota
  if command -v ping >/dev/null 2>&1; then
    if ping -c1 -W "$TIMEOUT" "$h" >/dev/null 2>&1; then
      echo "ping ok" | tee -a "$LOG_PATH"
    else
      echo "ping falhou (possivel rota/firewall)" | tee -a "$LOG_PATH"
    fi
  else
    echo "(ping indisponivel, pulando teste de ICMP)" | tee -a "$LOG_PATH"
  fi

  set +e
  ssh -i "$KEY_PATH" \
    -o BatchMode=yes \
    -o NumberOfPasswordPrompts=0 \
    -o ConnectTimeout="$TIMEOUT" \
    $SSH_OPTS \
    "$SSH_USER@$h" echo ok 2>&1 | tee -a "$LOG_PATH"
  rc=${PIPESTATUS[0]}
  set -e

  if [[ $rc -eq 0 ]]; then
    echo "[OK] $h" | tee -a "$LOG_PATH"
    ok=$((ok+1))
  else
    echo "[FALHA] $h" | tee -a "$LOG_PATH"
    fail=$((fail+1))
  fi
  echo | tee -a "$LOG_PATH"
done

echo "Resumo: OK=$ok FALHA=$fail" | tee -a "$LOG_PATH"
if [[ $fail -gt 0 ]]; then exit 1; fi
