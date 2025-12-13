#!/usr/bin/env bash
# Check for private keys accidentally committed in the repository
set -euo pipefail

echo "Searching for private key patterns in staged files..."
patterns=("-----BEGIN OPENSSH PRIVATE KEY-----" "-----BEGIN RSA PRIVATE KEY-----" "-----BEGIN PRIVATE KEY-----")
found=0
# If Git index is present, scan staged files first
if git rev-parse --git-dir >/dev/null 2>&1; then
  # Exclude known scanner and workflow files from false positives
  exclude_paths=("scripts/check_no_private_keys.sh" "scripts/check_no_private_keys.ps1" ".githooks/pre-commit" ".github/workflows/scan-keys.yml")
  for p in "${patterns[@]}"; do
    # Build a git grep exclude pathspec
    pathspec_args=()
    for ex in "${exclude_paths[@]}"; do
      pathspec_args+=("--" ":(exclude)$ex")
    done
    if git grep -n --cached -- "${p}" -- "${pathspec_args[@]}" >/dev/null 2>&1; then
      echo "Found pattern '${p}' in staged files:"
      git grep -n --cached -- "${p}" -- "${pathspec_args[@]}"
      found=1
    fi
  done
else
  echo "Not a git repository; scanning all files on disk..."
  for p in "${patterns[@]}"; do
    if grep -RIn -- "${p}" . >/dev/null 2>&1; then
      echo "Found pattern '${p}' in repository files:";
      grep -RIn -- "${p}" . || true
      found=1
    fi
  done
fi

if [ $found -eq 0 ]; then
  echo "No obvious private-key PEM blocks found in repo files."
else
  echo "One or more private key patterns were found. Review output above."
  exit 1
fi
