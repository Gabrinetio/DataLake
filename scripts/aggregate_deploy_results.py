#!/usr/bin/env python3
import json, glob, os, sys
from datetime import datetime

in_dir = 'artifacts/results'
out_dir = 'artifacts/reports'
os.makedirs(out_dir, exist_ok=True)
files = glob.glob(os.path.join(in_dir, '*_results.json')) + glob.glob(os.path.join(in_dir, 'p1_coverage_*.json'))
merged = []
for f in files:
    try:
        with open(f) as fh:
            obj = json.load(fh)
            if isinstance(obj, list):
                merged.extend(obj)
            else:
                merged.append(obj)
    except Exception as e:
        print('WARN: failed to load', f, e, file=sys.stderr)

outname = os.path.join(out_dir, f'DEPLOY_SUMMARY_{datetime.utcnow().strftime("%Y%m%dT%H%M%SZ")}.json')
with open(outname, 'w', encoding='utf-8') as ofh:
    json.dump(merged, ofh, indent=2, ensure_ascii=False)
print('Wrote', outname)
