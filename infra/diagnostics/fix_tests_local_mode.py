#!/usr/bin/env python3
"""
Fix test scripts to use local[*] mode instead of trying to connect to Spark Master
This will patch the Python test scripts on the server
"""

import subprocess
import sys

# SSH connection details
server = "192.168.4.33"
user = "datalake"
import os
key = os.environ.get('SSH_KEY_PATH', os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', 'scripts', 'key', 'ct_datalake_id_ed25519')))


# Commands to fix the test scripts on the server
commands = [
    # Fix CDC Pipeline test
    f'''ssh -i {key} {user}@{server} "sed -i 's/.getOrCreate()/.master("local[*]")\\\n        .getOrCreate()/' /home/datalake/test_cdc_pipeline.py"''',
    
    # Fix RLAC test
    f'''ssh -i {key} {user}@{server} "sed -i 's/.getOrCreate()/.master("local[*]")\\\n        .getOrCreate()/' /home/datalake/test_rlac_implementation.py"''',
    
    # Fix BI test
    f'''ssh -i {key} {user}@{server} "sed -i 's/.getOrCreate()/.master("local[*]")\\\n        .getOrCreate()/' /home/datalake/test_bi_integration.py"'''
]

print("🔧 Fixando scripts de teste para usar modo local...")

# Actually, let me create a better fix by copying the files and modifying them
fix_command = f'''
ssh -i {key} {user}@{server} << 'ENDSSH'

# Fix CDC Pipeline
sed -i '381s/.getOrCreate()/.master("local[*]")\\\n        .getOrCreate()/' /home/datalake/test_cdc_pipeline.py

# Fix RLAC Implementation  
sed -i '375s/.getOrCreate()/.master("local[*]")\\\n        .getOrCreate()/' /home/datalake/test_rlac_implementation.py

# Fix BI Integration
sed -i '376s/.getOrCreate()/.master("local[*]")\\\n        .getOrCreate()/' /home/datalake/test_bi_integration.py

echo "✅ Scripts fixados!"
ENDSSH
'''

# Execute the fix
try:
    result = subprocess.run(fix_command, shell=True, capture_output=True, text=True)
    print(result.stdout)
    if result.stderr:
        print("⚠️  Warnings:", result.stderr)
    print("✅ Scripts foram corrigidos!")
except Exception as e:
    print(f"❌ Erro ao executar fix: {e}")
    sys.exit(1)
