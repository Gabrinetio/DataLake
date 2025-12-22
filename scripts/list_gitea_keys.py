#!/usr/bin/env python3
import os, urllib.request, json, sys
token = os.getenv("GITEA_TOKEN")
if not token:
    print("GITEA_TOKEN not set", file=sys.stderr); sys.exit(1)
try:
    req=urllib.request.Request('http://gitea.gti.local/api/v1/repos/gitea/Datalake_FB/keys', headers={'Authorization': f'token {token}'})
    resp=urllib.request.urlopen(req, timeout=10)
    data=json.load(resp)
    print(json.dumps(data, indent=2))
except Exception as e:
    print('error', e, file=sys.stderr)
    sys.exit(1)
