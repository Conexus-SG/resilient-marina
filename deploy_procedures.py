#!/usr/bin/env python3
"""
Deploy the updated merge stored procedures to the Oracle database.
This script reads the .sql files and executes them to update the procedures.
"""

import json
import os
from molo_db_functions import OracleConnector


def deploy_procedures():
    """Deploy the 5 updated merge procedures."""
    
    print("="*70)
    print("Deploying Updated Merge Procedures")
    print("="*70)
    
    # Load config
    try:
        with open('config.json', 'r') as f:
            config = json.load(f)
    except FileNotFoundError:
        print("❌ config.json not found.")
        return
    
    # Connect to database
    try:
        db = OracleConnector(
            user=config['database']['user'],
            password=config['database']['password'],
            dsn=config['database']['dsn']
        )
        print("✅ Connected to Oracle database\n")
    except Exception as e:
        print(f"❌ Failed to connect to database: {e}")
        return
    
    # List of procedures to deploy
    procedures = [
        ('SP_RUN_ALL_MOLO_STELLAR_MERGES',
         'stored_procedures/sp_run_all_merges.sql'),
        ('SP_MERGE_MOLO_BOATS', 'stored_procedures/sp_merge_molo_boats.sql'),
        ('SP_MERGE_MOLO_INVOICES',
         'stored_procedures/sp_merge_molo_invoices.sql'),
        ('SP_MERGE_MOLO_ITEM_MASTERS',
         'stored_procedures/sp_merge_molo_item_masters.sql'),
        ('SP_MERGE_MOLO_RESERVATIONS',
         'stored_procedures/sp_merge_molo_reservations.sql'),
        ('SP_MERGE_MOLO_CONTACTS',
         'stored_procedures/sp_merge_molo_contacts.sql'),
    ]
    
    deployed = 0
    failed = 0
    
    for proc_name, sql_file in procedures:
        print(f"\n{'─'*70}")
        print(f"Deploying: {proc_name}")
        print(f"From: {sql_file}")
        print(f"{'─'*70}")
        
        # Check if file exists
        if not os.path.exists(sql_file):
            print(f"❌ File not found: {sql_file}")
            failed += 1
            continue
        
        # Read SQL file
        try:
            with open(sql_file, 'r') as f:
                sql_content = f.read()
        except Exception as e:
            print(f"❌ Failed to read file: {e}")
            failed += 1
            continue
        
        # Execute SQL
        try:
            # Remove the trailing slash and any whitespace
            sql_content = sql_content.strip()
            if sql_content.endswith('/'):
                sql_content = sql_content[:-1].strip()
            
            db.cursor.execute(sql_content)
            db.connection.commit()
            print(f"✅ {proc_name} deployed successfully!")
            deployed += 1
            
        except Exception as e:
            print(f"❌ Failed to deploy {proc_name}: {e}")
            failed += 1
    
    # Summary
    print(f"\n{'='*70}")
    print("DEPLOYMENT SUMMARY")
    print(f"{'='*70}")
    print(f"✅ Deployed: {deployed}/{len(procedures)}")
    print(f"❌ Failed: {failed}/{len(procedures)}")
    
    if deployed == len(procedures):
        print("\n🎉 All procedures deployed successfully!")
        print("\nNext step: Run test_merge_procedures.py to verify")
    else:
        print("\n⚠️  Some procedures failed to deploy.")
    
    # Close connection
    db.close()
    print(f"\n{'='*70}\n")


if __name__ == '__main__':
    deploy_procedures()
