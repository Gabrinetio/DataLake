#!/usr/bin/env python3
import os, json, sys, urllib.request

def main():
    token = os.getenv("GITEA_TOKEN")
    if not token:
        print("GITEA_TOKEN not set", file=sys.stderr); sys.exit(1)
    with open('scripts/key/ct_datalake_id_ed25519.pub','r') as f:
        pub = f.read().strip()
    data = {'title':'deploy-canonical-key','key':pub,'read_only':False}
    b = json.dumps(data).encode()
    req = urllib.request.Request('http://gitea.gti.local/api/v1/repos/gitea/Datalake_FB/keys', data=b, headers={'Content-Type':'application/json','Authorization': f'token {token}'})
    try:
        resp = urllib.request.urlopen(req, timeout=10)
        print(resp.read().decode())
    except urllib.error.HTTPError as e:
        print(e.code, e.read().decode(), file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print('error', e, file=sys.stderr)
        sys.exit(2)

if __name__=='__main__':
    main()
