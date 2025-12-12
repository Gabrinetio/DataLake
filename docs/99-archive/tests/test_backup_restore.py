#!/usr/bin/env python3
"""
Iteration 4: Backup & Restore Procedures
========================================

Purpose:
  - Create table backups
  - Implement restore procedures
  - Validate backup integrity
  - Test recovery scenarios
  
Success Criteria:
  - Backup created successfully
  - Restore recovers all data
  - Zero data loss on restore
  - Recovery time < 5 minutes
"""

import os
import sys
import json
import time
import shutil
from datetime import datetime
from pathlib import Path
from pyspark.sql import SparkSession
from src.config import get_spark_s3_config


class BackupRestoreManager:
    """Handle Iceberg table backup and restore"""
    
    def __init__(self):
        """Initialize Spark session with Iceberg"""
        spark_config = get_spark_s3_config()
        self.spark = SparkSession.builder \
            .appName("Iceberg_Backup_Restore") \
            .master("local[2]") \
            .config("spark.sql.extensions", 
                   "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions") \
            .config("spark.sql.catalog.hadoop_prod", 
                   "org.apache.iceberg.spark.SparkCatalog") \
            .config("spark.sql.catalog.hadoop_prod.type", "hadoop") \
            .config("spark.sql.catalog.hadoop_prod.warehouse", 
                   "s3a://datalake/warehouse") \
            .config("spark.jars.packages", 
                   "org.apache.hadoop:hadoop-aws:3.3.4," \
                   "org.apache.iceberg:iceberg-spark-runtime-3.5_2.12:1.10.0") \
            .getOrCreate()
        
        self.spark.sparkContext.setLogLevel("WARN")
        print("\n✅ SparkSession initialized\n")
        
        self.backup_dir = "/tmp/backups"
        os.makedirs(self.backup_dir, exist_ok=True)
        # Ensure directory has write permissions
        os.chmod(self.backup_dir, 0o777)
    
    def create_backup(self, table_name, backup_name=None):
        """Create a backup of table data and metadata"""
        print(f"\n💾 CREATING BACKUP for {table_name}")
        print("=" * 70)
        
        if backup_name is None:
            backup_name = f"backup_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
        
        backup_path = os.path.join(self.backup_dir, backup_name)
        
        start_time = time.time()
        
        try:
            # Export table to Parquet
            export_df = self.spark.sql(f"SELECT * FROM {table_name}")
            
            num_rows = export_df.count()
            
            export_df.coalesce(1).write \
                .mode("overwrite") \
                .parquet(backup_path)
            
            elapsed = time.time() - start_time
            
            # Get backup metadata
            backup_size = sum(f.stat().st_size for f in Path(backup_path).rglob("*") if f.is_file())
            
            backup_info = {
                "backup_name": backup_name,
                "table": table_name,
                "row_count": num_rows,
                "size_bytes": backup_size,
                "size_mb": backup_size / (1024**2),
                "backup_time_seconds": elapsed,
                "timestamp": datetime.now().isoformat(),
                "path": backup_path,
                "status": "SUCCESS"
            }
            
            print(f"  ✅ Backup created: {backup_name}")
            print(f"  📝 Rows: {num_rows:,}")
            print(f"  💾 Size: {backup_info['size_mb']:.2f} MB")
            print(f"  ⏱️  Time: {elapsed:.2f}s")
            
            return backup_info
            
        except Exception as e:
            elapsed = time.time() - start_time
            print(f"  ❌ Backup failed: {str(e)[:100]}")
            return {
                "backup_name": backup_name,
                "status": "FAILED",
                "error": str(e)[:100],
                "time_seconds": elapsed
            }
    
    def restore_backup(self, backup_name, restore_table_name):
        """Restore a backup to a new table"""
        print(f"\n📥 RESTORING BACKUP: {backup_name}")
        print("=" * 70)
        
        backup_path = os.path.join(self.backup_dir, backup_name)
        
        start_time = time.time()
        
        try:
            # Read from backup
            restore_df = self.spark.read.parquet(backup_path)
            
            # Write to new Iceberg table
            restore_df.writeTo(restore_table_name).create()
            
            elapsed = time.time() - start_time
            
            # Verify restore
            verify_count = self.spark.sql(
                f"SELECT COUNT(*) FROM {restore_table_name}"
            ).collect()[0][0]
            
            restore_info = {
                "backup_name": backup_name,
                "restore_table": restore_table_name,
                "rows_restored": verify_count,
                "restore_time_seconds": elapsed,
                "timestamp": datetime.now().isoformat(),
                "status": "SUCCESS"
            }
            
            print(f"  ✅ Restore completed: {restore_table_name}")
            print(f"  📝 Rows restored: {verify_count:,}")
            print(f"  ⏱️  Time: {elapsed:.2f}s")
            
            return restore_info
            
        except Exception as e:
            elapsed = time.time() - start_time
            print(f"  ❌ Restore failed: {str(e)[:100]}")
            return {
                "backup_name": backup_name,
                "restore_table": restore_table_name,
                "status": "FAILED",
                "error": str(e)[:100],
                "time_seconds": elapsed
            }
    
    def validate_backup_integrity(self, original_table, backup_name):
        """Validate backup integrity by comparing checksums"""
        print(f"\n🔍 VALIDATING BACKUP INTEGRITY")
        print("=" * 70)
        
        try:
            # Get original table statistics
            original_count = self.spark.sql(
                f"SELECT COUNT(*) FROM {original_table}"
            ).collect()[0][0]
            
            original_sum = self.spark.sql(f"""
                SELECT SUM(CAST(transaction_id AS LONG)) as checksum 
                FROM {original_table}
            """).collect()[0][0] or 0
            
            # Read backup
            backup_path = os.path.join(self.backup_dir, backup_name)
            backup_df = self.spark.read.parquet(backup_path)
            
            backup_count = backup_df.count()
            
            backup_sum = self.spark.sql(f"""
                SELECT SUM(CAST(transaction_id AS LONG)) as checksum 
                FROM parquet.`{backup_path}`
            """).collect()[0][0] or 0
            
            # Compare
            matches = (original_count == backup_count) and (original_sum == backup_sum)
            
            validation = {
                "original_rows": original_count,
                "backup_rows": backup_count,
                "original_checksum": original_sum,
                "backup_checksum": backup_sum,
                "integrity_check": "PASS" if matches else "FAIL",
                "status": "VALID" if matches else "CORRUPTED"
            }
            
            print(f"  📝 Original rows: {original_count:,}")
            print(f"  📝 Backup rows: {backup_count:,}")
            print(f"  🔐 Original checksum: {original_sum}")
            print(f"  🔐 Backup checksum: {backup_sum}")
            print(f"  ✅ Integrity: {validation['status']}")
            
            return validation
            
        except Exception as e:
            print(f"  ❌ Validation failed: {str(e)[:100]}")
            return {
                "status": "FAILED",
                "error": str(e)[:100]
            }
    
    def list_backups(self):
        """List all available backups"""
        print(f"\n📂 AVAILABLE BACKUPS")
        print("=" * 70)
        
        backups = []
        
        try:
            for backup_dir in Path(self.backup_dir).iterdir():
                if backup_dir.is_dir():
                    size = sum(f.stat().st_size for f in backup_dir.rglob("*") if f.is_file())
                    
                    backup_info = {
                        "name": backup_dir.name,
                        "size_mb": size / (1024**2),
                        "created": datetime.fromtimestamp(backup_dir.stat().st_mtime).isoformat()
                    }
                    
                    backups.append(backup_info)
                    
                    print(f"  📦 {backup_dir.name}")
                    print(f"     Size: {backup_info['size_mb']:.2f} MB")
                    print(f"     Created: {backup_info['created']}")
            
            print(f"\n  Total backups: {len(backups)}")
            
        except Exception as e:
            print(f"  ❌ Error listing backups: {str(e)[:100]}")
        
        return backups
    
    def run(self):
        """Execute full backup/restore workflow"""
        print("\n" + "="*70)
        print("💾 BACKUP & RESTORE PROCEDURES - ITERATION 4")
        print("="*70)
        
        table_name = "hadoop_prod.default.vendas_small"
        
        # 1. Create backup
        backup_result = self.create_backup(table_name, "vendas_small_backup_v1")
        
        # 2. Validate backup
        validation_result = self.validate_backup_integrity(table_name, "vendas_small_backup_v1")
        
        # 3. List backups
        backups = self.list_backups()
        
        # 4. Test restore
        restore_table = "hadoop_prod.default.vendas_small_restored"
        restore_result = self.restore_backup("vendas_small_backup_v1", restore_table)
        
        # 5. Verify restored data
        print(f"\n🔍 VERIFYING RESTORED DATA")
        print("=" * 70)
        
        try:
            original_count = self.spark.sql(f"SELECT COUNT(*) FROM {table_name}").collect()[0][0]
            restored_count = self.spark.sql(f"SELECT COUNT(*) FROM {restore_table}").collect()[0][0]
            
            match = original_count == restored_count
            
            print(f"  Original table: {original_count:,} rows")
            print(f"  Restored table: {restored_count:,} rows")
            print(f"  ✅ Match: {'YES' if match else 'NO'}")
            
            verification = {
                "original_count": original_count,
                "restored_count": restored_count,
                "match": match,
                "status": "SUCCESS" if match else "MISMATCH"
            }
        except Exception as e:
            verification = {
                "status": "FAILED",
                "error": str(e)[:100]
            }
        
        # 6. Summary
        print(f"\n📊 BACKUP & RESTORE SUMMARY")
        print("=" * 70)
        
        print(f"  ✅ Backup created: {backup_result.get('status')}")
        print(f"  ✅ Backup integrity: {validation_result.get('status')}")
        print(f"  ✅ Data restored: {restore_result.get('status')}")
        print(f"  ✅ Verification: {verification.get('status')}")
        
        # 7. Save results
        results = {
            "timestamp": datetime.now().isoformat(),
            "table": table_name,
            "backup": backup_result,
            "validation": validation_result,
            "restore": restore_result,
            "verification": verification,
            "backups_available": backups,
            "summary": {
                "backup_status": backup_result.get("status"),
                "restore_status": restore_result.get("status"),
                "data_integrity": validation_result.get("status"),
                "verification_status": verification.get("status"),
                "overall_status": "SUCCESS" if all([
                    backup_result.get("status") == "SUCCESS",
                    validation_result.get("status") == "VALID",
                    restore_result.get("status") == "SUCCESS",
                    verification.get("status") == "SUCCESS"
                ]) else "PARTIAL"
            }
        }
        
        output_file = "/tmp/backup_restore_results.json"
        with open(output_file, "w") as f:
            json.dump(results, f, indent=2)
        
        print(f"\n✅ BACKUP & RESTORE TEST COMPLETO")
        print(f"📁 Results saved to: {output_file}")
        
        return results


if __name__ == "__main__":
    manager = BackupRestoreManager()
    manager.run()
