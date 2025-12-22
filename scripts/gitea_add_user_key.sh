#!/usr/bin/env bash
# scripts/gitea_add_user_key.sh
# Add an SSH key to a Gitea user account via API.
# Usage:
#   GITEA_TOKEN=<token> ./scripts/gitea_add_user_key.sh --host 192.168.4.26 --key scripts/key/ct_datalake_id_ed25519.pub --title "canonical-automation"

set -euo pipefail

HOST="192.168.4.26"
KEY_PATH=""
TITLE="canonical-automation"

while [[ $# -gt 0 ]]; do
  case $1 in
    --host) HOST="$2"; shift 2;;
    --key) KEY_PATH="$2"; shift 2;;
    --title) TITLE="$2"; shift 2;;
    *) echo "Unknown param: $1"; exit 1;;
  esac
done

if [ -z "$KEY_PATH" ]; then
  echo "Key path is required: --key path/to/key.pub"; exit 2
fi
if [ ! -f "$KEY_PATH" ]; then
  echo "Key file not found: $KEY_PATH"; exit 3
fi
if [ -z "${GITEA_TOKEN:-}" ]; then
  echo "GITEA_TOKEN env var is required (Personal Access Token)"; exit 4
fi

KEY_DATA=$(cat "$KEY_PATH" | tr -d '\n')
API_URL="http://${HOST}/api/v1/user/keys"
PAYLOAD=$(jq -nc --arg k "$KEY_DATA" --arg t "$TITLE" '{key:$k,title:$t}')

echo "Adding user key to Gitea at ${HOST} (title: $TITLE)"
resp=$(curl -sS -w '%{http_code}' -X POST -H "Content-Type: application/json" -H "Authorization: token ${GITEA_TOKEN}" -d "$PAYLOAD" "$API_URL")
http_code=${resp: -3}
body=${resp:0:-3}

if [[ "$http_code" =~ ^2 ]]; then
  echo "User key added successfully."; echo "$body" | jq .; exit 0
else
  echo "Failed to add user key (HTTP $http_code)"; echo "$body" | jq .; exit 5
fi
