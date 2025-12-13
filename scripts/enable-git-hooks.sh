#!/usr/bin/env bash
set -euo pipefail

echo "Setting git hooksPath to .githooks for this repository..."
git config core.hooksPath .githooks
if [ -f .githooks/pre-commit ]; then
  chmod +x .githooks/pre-commit
  echo "Pre-commit hook installed (.githooks/pre-commit)."
else
  echo "Pre-commit hook not found at .githooks/pre-commit" >&2
  exit 1
fi

echo "Done. To revert: git config --unset core.hooksPath"
