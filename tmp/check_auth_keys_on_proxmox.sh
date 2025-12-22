#!/bin/bash
for ct in 107 108 109 115 116 117 118; do
  echo "=== CT $ct ==="
  pct exec $ct -- cat /home/datalake/.ssh/authorized_keys || echo "MISSING_FILE"
done
