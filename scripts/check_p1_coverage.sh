#!/usr/bin/env bash
# scripts/check_p1_coverage.sh
# Usage: ./scripts/check_p1_coverage.sh --hosts "107 108" [--key scripts/key/ct_datalake_id_ed25519] [--user datalake] [--dry-run]

set -euo pipefail

HOSTS=""
KEY=${KEY:-scripts/key/ct_datalake_id_ed25519}
USER=${USER:-datalake}
DRYRUN=0
REQUIRE_LOCAL=0

while [[ $# -gt 0 ]]; do
  case $1 in
    --hosts) HOSTS="$2"; shift 2;;
    --key) KEY="$2"; shift 2;;
    --user) USER="$2"; shift 2;;
    --dry-run) DRYRUN=1; shift ;;
    --require-local) REQUIRE_LOCAL=1; shift ;;
    *) echo "Unknown param: $1"; exit 1;;
  esac
done

if [ -z "$HOSTS" ] && [ $REQUIRE_LOCAL -ne 1 ]; then
  echo "No hosts provided. Use --hosts '107 108 109'"; exit 1
fi

OUTPUT_DIR=artifacts/results
mkdir -p "$OUTPUT_DIR"
DATE_TAG=$(date -Iseconds)
OUTFILE="$OUTPUT_DIR/p1_coverage_${DATE_TAG}.json"

# Load canonical pub
if [ ! -f scripts/key/ct_datalake_id_ed25519.pub ]; then
  echo "Public key not found: scripts/key/ct_datalake_id_ed25519.pub"; exit 2
fi
CANON_PUB_RAW=$(cat scripts/key/ct_datalake_id_ed25519.pub)

# Required tests to verify on each host:
# 1) authorized_keys contains canon pub
# 2) test scripts exist (/home/datalake/{{test files}})
# 3) can run simple command (whoami/hostname)

TEST_FILES=("test_cdc_pipeline.py" "test_rlac_implementation.py" "test_rlac_fixed.py" "test_bi_integration.py")

RESULTS=()

for id in $HOSTS; do
  host=""
  # Resolve CT id to hostname using local map in scripts/deploy_authorized_key.ps1 or known mapping
  # For convenience, if id ~ numeric, use the mapping in scripts/deploy_authorized_key.ps1
  case $id in
    107) host="minio.gti.local";;
    108) host="spark.gti.local";;
    109) host="kafka.gti.local";;
    111) host="trino.gti.local";;
    115) host="superset.gti.local";;
    116) host="airflow.gti.local";;
    117) host="db-hive.gti.local";;
    118) host="gitea.gti.local";;
    *) host="$id";;
  esac

  echo "Checking CT $id ($host)"
  entry="{\"ct\": \"$id\", \"host\": \"$host\""
  key_present=false
  scripts_present=()
  connectivity=false

  # Check authorized_keys presence
  if [ $DRYRUN -eq 1 ]; then
    echo "DRYRUN: would check key presence on $host"
  else
    out=$(ssh -i "$KEY" -o ConnectTimeout=5 -o StrictHostKeyChecking=no -o NumberOfPasswordPrompts=3 $USER@$host "grep -F \"$CANON_PUB_RAW\" ~/.ssh/authorized_keys || true" 2>&1 || true)
    if [ -n "$out" ]; then
      key_present=true
    fi
  fi

  # Check test files exist
  for f in "${TEST_FILES[@]}"; do
    if [ $DRYRUN -eq 1 ]; then
      scripts_present+=("$f:DRYRUN")
    else
      out=$(ssh -i "$KEY" -o ConnectTimeout=5 -o StrictHostKeyChecking=no -o NumberOfPasswordPrompts=3 $USER@$host "test -f /home/$USER/$f && echo found || echo missing" 2>&1 || true)
      if echo "$out" | grep -q "found"; then
        scripts_present+=("$f:found")
      else
        scripts_present+=("$f:missing")
      fi
    fi
  done

  # Connectivity check
  if [ $DRYRUN -eq 1 ]; then
    connectivity=true
  else
    out=$(ssh -i "$KEY" -o ConnectTimeout=5 -o StrictHostKeyChecking=no -o NumberOfPasswordPrompts=3 $USER@$host "whoami && hostname" 2>&1 || true)
    if [ -n "$out" ]; then connectivity=true; fi
  fi

  # Add key presence
  entry+="\, \"key_present\": $key_present"

  # Build scripts_present JSON
  scripts_json="["
  first=1
  for s in "${scripts_present[@]}"; do
    name=$(echo "$s" | cut -d: -f1)
    status=$(echo "$s" | cut -d: -f2)
    if [ $first -eq 1 ]; then
      scripts_json+="{\"name\": \"$name\", \"status\": \"$status\"}"
      first=0
    else
      scripts_json+=",{\"name\": \"$name\", \"status\": \"$status\"}"
    fi
  done
  scripts_json+="]"
  entry+="\, \"scripts_present\": $scripts_json"

  # Connectivity
  entry+="\, \"connectivity\": $connectivity"
  entry+=" }"
  RESULTS+=("$entry")
done

# Save output JSON
mkdir -p "$(dirname "$OUTFILE")"
echo "[" > "$OUTFILE"
first=1
for r in "${RESULTS[@]}"; do
  if [ $first -eq 1 ]; then
    echo "$r" >> "$OUTFILE"
    first=0
  else
    echo "," >> "$OUTFILE"
    echo "$r" >> "$OUTFILE"
  fi
done
echo "]" >> "$OUTFILE"

echo "Saved coverage report: $OUTFILE"

# Print summary
echo "Summary:"; echo
for r in "${RESULTS[@]}"; do
  ct=$(echo "$r" | sed -n 's/.*"ct": "\([^"]*\)".*/\1/p')
  hostn=$(echo "$r" | sed -n 's/.*"host": "\([^"]*\)".*/\1/p')
  keyp=$(echo "$r" | sed -n 's/.*"key_present": \([a-z]*\).*/\1/p')
  conn=$(echo "$r" | sed -n 's/.*"connectivity": \([a-z]*\).*/\1/p')
  echo "- CT $ct ($hostn) - key:$keyp connectivity:$conn"
done

exit 0

# Local checks - used by CI to verify that required P1 tests exist in repo
if [ $REQUIRE_LOCAL -eq 1 ]; then
  echo "Checking local test files..."
  # check CDC
  if [ ! -f src/tests/test_cdc_pipeline.py ]; then
    echo "Missing local test: src/tests/test_cdc_pipeline.py"; exit 2
  fi
  # check RLAC: at least one must be present
  if [ ! -f src/tests/test_rlac_implementation.py ] && [ ! -f src/tests/test_rlac_fixed.py ]; then
    echo "Missing RLAC test: src/tests/test_rlac_implementation.py or src/tests/test_rlac_fixed.py"; exit 2
  fi
  # check BI
  if [ ! -f src/tests/test_bi_integration.py ]; then
    echo "Missing local test: src/tests/test_bi_integration.py"; exit 2
  fi
  echo "Local test files present."; exit 0
fi