#!/usr/bin/env bash
# Helper: Upload tests and run run_tests.sh on remote server with retries
# Usage: ./ssh_and_run_tests.sh user@hostname

set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 user@host"
  exit 1
fi

REMOTE="$1"
REMOTE_DIR="/home/datalake"

FILES_TO_UPLOAD=(run_tests.sh src/tests/test_rlac_implementation.py src/tests/test_cdc_pipeline.py src/tests/test_bi_integration.py src/tests/test_backup_restore_simple.py)

RETRIES=3
SLEEP=5

function upload_files() {
  for f in "${FILES_TO_UPLOAD[@]}"; do
    echo "Uploading ${f} -> ${REMOTE}:${REMOTE_DIR}/${f}"
    if [ -n "${SSH_KEY:-}" ]; then
      scp -i "${SSH_KEY}" -r "$f" "${REMOTE}:${REMOTE_DIR}/" || return 1
    else
      scp -r "$f" "${REMOTE}:${REMOTE_DIR}/" || return 1
    fi
  done
  return 0
}

# Try upload with retries
COUNT=0
until upload_files; do
  COUNT=$((COUNT+1))
  if [ ${COUNT} -ge ${RETRIES} ]; then
    echo "Failed to upload files after ${RETRIES} attempts"
    exit 2
  fi
  echo "Upload failed. Retrying in ${SLEEP}s... (${COUNT}/${RETRIES})"
  sleep ${SLEEP}
done

# Run tests remotely
if [ -n "${SSH_KEY:-}" ]; then
  ssh -i "${SSH_KEY}" "${REMOTE}" "bash -lc 'cd ${REMOTE_DIR} && ./run_tests.sh |& tee /tmp/test_execution.log'"
else
  ssh "${REMOTE}" "bash -lc 'cd ${REMOTE_DIR} && ./run_tests.sh |& tee /tmp/test_execution.log'"
fi

# Fetch results
if [ -n "${SSH_KEY:-}" ]; then
  scp -i "${SSH_KEY}" "${REMOTE}:/tmp/*_results.json" ./src/results/ || true
  scp -i "${SSH_KEY}" "${REMOTE}:/tmp/test_execution.log" ./src/results/ || true
else
  scp "${REMOTE}:/tmp/*_results.json" ./src/results/ || true
  scp "${REMOTE}:/tmp/test_execution.log" ./src/results/ || true
fi

echo "Done. Results downloaded to ./src/results/ (where available)"

exit 0
