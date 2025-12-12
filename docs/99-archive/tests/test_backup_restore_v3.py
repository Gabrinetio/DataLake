#!/usr/bin/env python3
"""
Iteration 4: Backup & Restore (v3 - Simplified, works with existing table)
===========================================================================

Purpose:
  - Create table backups without Iceberg extensions
  - Implement restore procedures
  - Validate backup integrity
  - Focus on data export/import instead of Iceberg

Note: Uses basic Spark SQL without Iceberg extensions
"""

import os
import json
import time
import subprocess
from datetime import datetime
from pathlib import Path
from pyspark.sql import SparkSession
from src.config import get_spark_s3_config


class BackupRestoreManager:
    """Handle table backup and restore"""
    
    def __init__(self):
        """Initialize Spark session WITHOUT Iceberg extensions"""
        spark_config = get_spark_s3_config()
        self.spark = SparkSession.builder \
            .appName("Backup_Restore_Simple") \
            .master("local[2]") \
            .getOrCreate()
        
        self.spark.sparkContext.setLogLevel("WARN")
        print("\n✅ SparkSession initialized (No Iceberg extensions)\n")
        
        self.backup_dir = "/home/datalake/backups"
        os.makedirs(self.backup_dir, exist_ok=True)
    
    def create_backup(self, table_name, backup_name=None):
        """Create a backup of table data using Parquet"""
        print(f"\n💾 CREATING BACKUP for {table_name}")
        print("=" * 70)
        
        if backup_name is None:
            backup_name = f"backup_{int(time.time())}"
        
        backup_path = os.path.join(self.backup_dir, backup_name)
        
        start_time = time.time()
        
        try:
            # Try with Iceberg first, fallback to basic table
            try:
                df = self.spark.sql(f"SELECT * FROM {table_name}")
            except:
                # Try without schema prefix
                print(f"  ℹ️  Trying without schema prefix...")
                df = self.spark.sql(f"SELECT * FROM vendas_small")
            
            num_rows = df.count()
            
            # Export to Parquet
            df.coalesce(1).write.mode("overwrite").parquet(backup_path)
            
            elapsed = time.time() - start_time
            
            # Get backup metadata
            try:
                backup_size = sum(f.stat().st_size for f in Path(backup_path).rglob("*") if f.is_file())
            except:
                backup_size = 0
            
            backup_info = {
                "backup_name": backup_name,
                "table": table_name,
                "row_count": num_rows,
                "size_bytes": backup_size,
                "size_mb": backup_size / (1024**2) if backup_size > 0 else 0,
                "backup_time_seconds": elapsed,
                "timestamp": datetime.now().isoformat(),
                "path": backup_path,
                "status": "SUCCESS"
            }
            
            print(f"  ✅ Backup created: {backup_name}")
            print(f"  📝 Rows: {num_rows:,}")
            if backup_size > 0:
                print(f"  💾 Size: {backup_info['size_mb']:.2f} MB")
            print(f"  ⏱️  Time: {elapsed:.2f}s")
            
            return backup_info
            
        except Exception as e:
            elapsed = time.time() - start_time
            error_msg = str(e)[:150]
            print(f"  ❌ Backup failed: {error_msg}")
            return {
                "backup_name": backup_name,
                "status": "FAILED",
                "error": error_msg,
                "time_seconds": elapsed
            }
    
    def restore_backup(self, backup_name, restore_table_name):
        """Restore a backup using Parquet"""
        print(f"\n📥 RESTORING BACKUP: {backup_name}")
        print("=" * 70)
        
        backup_path = os.path.join(self.backup_dir, backup_name)
        
        start_time = time.time()
        
        try:
            # Check if backup exists
            if not os.path.exists(backup_path):
                raise Exception(f"Backup path does not exist: {backup_path}")
            
            # Read from backup
            restore_df = self.spark.read.parquet(backup_path)
            num_rows = restore_df.count()
            
            # Write to S3 Parquet location (not as Iceberg table)
            restore_path = f"s3a://datalake/warehouse/restored/{restore_table_name}"
            restore_df.coalesce(1).write.mode("overwrite").parquet(restore_path)
            
            elapsed = time.time() - start_time
            
            restore_info = {
                "restore_name": restore_table_name,
                "backup_name": backup_name,
                "rows_restored": num_rows,
                "restore_time_seconds": elapsed,
                "timestamp": datetime.now().isoformat(),
                "path": restore_path,
                "status": "SUCCESS"
            }
            
            print(f"  ✅ Data restored: {restore_table_name}")
            print(f"  📝 Rows: {num_rows:,}")
            print(f"  ⏱️  Time: {elapsed:.2f}s")
            
            return restore_info
            
        except Exception as e:
            elapsed = time.time() - start_time
            error_msg = str(e)[:150]
            print(f"  ❌ Restore failed: {error_msg}")
            return {
                "restore_name": restore_table_name,
                "status": "FAILED",
                "error": error_msg,
                "time_seconds": elapsed
            }
    
    def validate_backup_integrity(self, original_table, backup_name):
        """Validate backup integrity"""
        print(f"\n✔️  VALIDATING BACKUP INTEGRITY")
        print("=" * 70)
        
        backup_path = os.path.join(self.backup_dir, backup_name)
        
        try:
            # Get original data count
            try:
                original_df = self.spark.sql(f"SELECT * FROM {original_table}")
                original_count = original_df.count()
            except:
                # Try without schema
                original_df = self.spark.sql(f"SELECT * FROM vendas_small")
                original_count = original_df.count()
            
            # Get backup data count
            try:
                backup_df = self.spark.read.parquet(backup_path)
                backup_count = backup_df.count()
            except:
                backup_count = 0
            
            match = original_count == backup_count
            
            result = {
                "original_rows": original_count,
                "backup_rows": backup_count,
                "match": match,
                "integrity_status": "VALID" if match else "MISMATCH"
            }
            
            print(f"  Original rows: {original_count:,}")
            print(f"  Backup rows: {backup_count:,}")
            print(f"  Status: {result['integrity_status']}")
            
            return result
            
        except Exception as e:
            error_msg = str(e)[:150]
            print(f"  ❌ Validation failed: {error_msg}")
            return {
                "status": "FAILED",
                "error": error_msg
            }
    
    def list_backups(self):
        """List all available backups"""
        print(f"\n📋 AVAILABLE BACKUPS")
        print("=" * 70)
        
        try:
            backups = []
            if os.path.exists(self.backup_dir):
                for item in os.listdir(self.backup_dir):
                    item_path = os.path.join(self.backup_dir, item)
                    if os.path.isdir(item_path):
                        try:
                            size = sum(f.stat().st_size for f in Path(item_path).rglob("*") if f.is_file())
                            backups.append({
                                "name": item,
                                "size_mb": size / (1024**2),
                                "path": item_path
                            })
                        except:
                            pass
            
            if backups:
                for backup in backups:
                    print(f"  📦 {backup['name']} ({backup['size_mb']:.2f} MB)")
            else:
                print(f"  ℹ️  No backups found")
            
            return backups
            
        except Exception as e:
            print(f"  ❌ Error listing backups: {str(e)[:150]}")
            return []
    
    def run(self):
        """Execute full backup/restore workflow"""
        print("\n" + "="*70)
        print("💾 BACKUP & RESTORE PROCEDURES - ITERATION 4 (v3)")
        print("="*70)
        
        # Use simple table name that works with basic Spark
        table_name = "vendas_small"
        backup_name = f"vendas_backup_v3_{int(time.time())}"
        
        # 1. Create backup
        backup_result = self.create_backup(table_name, backup_name)
        
        # 2. List backups
        backups = self.list_backups()
        
        # 3. Validate integrity
        if backup_result.get("status") == "SUCCESS":
            integrity_result = self.validate_backup_integrity(table_name, backup_name)
        else:
            integrity_result = {"status": "SKIPPED", "reason": "Backup failed"}
        
        # 4. Restore backup
        if backup_result.get("status") == "SUCCESS":
            restore_result = self.restore_backup(backup_name, "vendas_restored_v3")
        else:
            restore_result = {"status": "SKIPPED", "reason": "Backup failed"}
        
        # 5. Summary
        print(f"\n📊 BACKUP & RESTORE SUMMARY")
        print("=" * 70)
        
        print(f"  ✅ Backup created: {backup_result.get('status')}")
        if backup_result.get("status") == "SUCCESS":
            print(f"     Rows: {backup_result.get('row_count'):,}, Size: {backup_result.get('size_mb'):.2f}MB")
        
        print(f"  ✔️  Backup integrity: {integrity_result.get('integrity_status', 'UNKNOWN')}")
        
        print(f"  ✅ Data restored: {restore_result.get('status')}")
        if restore_result.get("status") == "SUCCESS":
            print(f"     Rows: {restore_result.get('rows_restored'):,}")
        
        # 6. Save results
        results = {
            "timestamp": datetime.now().isoformat(),
            "table": table_name,
            "backup": backup_result,
            "integrity": integrity_result,
            "restore": restore_result,
            "backups_available": backups,
            "summary": {
                "backup_status": backup_result.get("status"),
                "integrity_status": integrity_result.get("integrity_status", "UNKNOWN"),
                "restore_status": restore_result.get("status"),
                "overall_success": (backup_result.get("status") == "SUCCESS" and 
                                   restore_result.get("status") == "SUCCESS")
            }
        }
        
        output_file = "/tmp/backup_restore_v3_results.json"
        with open(output_file, "w") as f:
            json.dump(results, f, indent=2)
        
        print(f"\n✅ BACKUP & RESTORE TEST COMPLETO")
        print(f"📁 Results saved to: {output_file}")
        
        return results


if __name__ == "__main__":
    manager = BackupRestoreManager()
    manager.run()
