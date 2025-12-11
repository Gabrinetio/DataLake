#!/usr/bin/env bash
# List files in the repo that reference s3a:// to make it easier to identify tests needing MinIO

set -euo pipefail

echo "Searching for s3a references in repo..."
grep -R "s3a://" -n || echo "No s3a references found"

echo "Done."

exit 0
