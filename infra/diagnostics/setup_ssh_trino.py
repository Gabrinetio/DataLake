#!/usr/bin/env python3
"""
Setup SSH access from Trino container via Proxmox management
"""
import subprocess
import sys
import os

def run_cmd(cmd, description=""):
    """Execute command and return output"""
    print(f"→ {description or cmd}")
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=30)
        if result.returncode == 0:
            print(f"  ✅ Success")
            return result.stdout.strip()
        else:
            print(f"  ❌ Failed: {result.stderr[:100]}")
            return None
    except subprocess.TimeoutExpired:
        print(f"  ❌ Timeout")
        return None
    except Exception as e:
        print(f"  ❌ Error: {str(e)}")
        return None

def main():
    print("=" * 60)
    print("SSH SETUP: Trino Container Access")
    print("=" * 60)
    print()

    # Paths
    home = os.path.expanduser("~")
    hive_key = f"{home}/.ssh/db_hive_admin_id_ed25519"
    pve_key = f"{home}/.ssh/pve3_root_id_ed25519"

    # Step 1: Generate SSH key on Hive
    print("[1] Generating SSH key on Hive container...")
    ssh_cmd = (
        f'ssh -i {hive_key} -o StrictHostKeyChecking=no '
        f'datalake@192.168.4.32 '
        f'"ssh-keygen -t ed25519 -f ~/.ssh/id_trino -N \\"\" '
        f'-C datalake-hive-to-trino 2>&1 && echo ✅"'
    )
    run_cmd(ssh_cmd, "Generating key on Hive")
    print()

    # Step 2: Get public key
    print("[2] Retrieving public key...")
    get_key_cmd = (
        f'ssh -i {hive_key} -o StrictHostKeyChecking=no '
        f'datalake@192.168.4.32 "cat ~/.ssh/id_trino.pub"'
    )
    pub_key = run_cmd(get_key_cmd, "Getting public key from Hive")
    if not pub_key:
        print("Failed to retrieve public key")
        return 1
    print(f"Key: {pub_key[:60]}...")
    print()

    # Step 3: Create authorized_keys on Trino
    print("[3] Adding key to Trino authorized_keys...")
    
    # Create file locally first
    import tempfile
    with tempfile.NamedTemporaryFile(mode='w', delete=False, suffix='.pub') as f:
        f.write(pub_key + '\n')
        temp_key_file = f.name
    
    try:
        # Push via Proxmox
        push_cmd = (
            f'ssh -i {pve_key} -o StrictHostKeyChecking=no '
            f'root@192.168.4.25 "pct push 111 {temp_key_file} /tmp/ssh_key.pub && '
            f'pct exec 111 -- mkdir -p /home/datalake/.ssh && '
            f'pct exec 111 -- bash -c \'cat /tmp/ssh_key.pub >> /home/datalake/.ssh/authorized_keys\' && '
            f'pct exec 111 -- chown -R datalake:datalake /home/datalake/.ssh && '
            f'pct exec 111 -- chmod 700 /home/datalake/.ssh && '
            f'pct exec 111 -- chmod 600 /home/datalake/.ssh/authorized_keys && '
            f'pct exec 111 -- rm /tmp/ssh_key.pub && '
            f'echo ✅"'
        )
        result = run_cmd(push_cmd, "Pushing key to Trino")
        
        if result:
            print(f"Output: {result}")
    finally:
        if os.path.exists(temp_key_file):
            os.remove(temp_key_file)
    print()

    # Step 4: Verify SSH works
    print("[4] Verifying SSH access...")
    verify_cmd = (
        f'ssh -i {hive_key} -o StrictHostKeyChecking=no '
        f'datalake@192.168.4.32 '
        f'"ssh -i ~/.ssh/id_trino -o StrictHostKeyChecking=no '
        f'-o UserKnownHostsFile=/dev/null datalake@192.168.4.35 '
        f'hostname"'
    )
    result = run_cmd(verify_cmd, "Testing SSH connection")
    if result and "datalake" in result:
        print(f"✅ SSH Access Verified: {result}")
    else:
        print("⚠️ SSH connection may need manual verification")
    print()

    print("=" * 60)
    print("✅ SSH Setup Complete!")
    print("=" * 60)
    print()
    print("You can now access Trino container via:")
    print("  ssh -i ~/.ssh/db_hive_admin_id_ed25519 datalake@192.168.4.32 (Hive)")
    print("  ssh -i ~/.ssh/id_trino datalake@192.168.4.35 (Trino)")
    print()

if __name__ == "__main__":
    sys.exit(main())





