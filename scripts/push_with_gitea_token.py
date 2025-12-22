#!/usr/bin/env python3
import os, subprocess, re, sys
p='.env'
if not os.path.exists(p):
    print('.env not found', file=sys.stderr); sys.exit(1)
with open('.env') as f:
    txt=f.read()
m=re.search(r'^GITEA_TOKEN=(.+)$', txt, flags=re.M)
if not m:
    print('token not found', file=sys.stderr); sys.exit(1)
token=m.group(1).strip()
# prepare git command
cmd=['git','-c',f'http.extraHeader=Authorization: token {token}','push','https://gitea.gti.local/gitea/Datalake_FB.git','chore/minio-spark-vault-20251222:chore/minio-spark-vault-20251222','-u']
print('Running:', ' '.join(cmd))
env=os.environ.copy()
env['GIT_SSL_NO_VERIFY']='true'
ret=subprocess.run(cmd, env=env)
if ret.returncode!=0:
    print('git push failed', file=sys.stderr)
    sys.exit(ret.returncode)
print('git push succeeded')
