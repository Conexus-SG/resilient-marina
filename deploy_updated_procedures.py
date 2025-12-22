#!/usr/bin/env python3
"""
Deploy all updated stored procedures with conditional WHERE clause pattern.
"""

import oracledb
import json
import os
import sys

# Read config
with open('config.json') as f:
    config = json.load(f)

# List of procedures with updated conditional WHERE clause pattern
UPDATED_PROCEDURES = [
    'sp_merge_molo_accounts.sql',
    'sp_merge_molo_boats.sql',
    'sp_merge_molo_contacts.sql',
    'sp_merge_molo_invoice_items.sql',
    'sp_merge_molo_invoices.sql',
    'sp_merge_molo_piers.sql',
    'sp_merge_molo_reservations.sql',
    'sp_merge_molo_slips.sql',
    'sp_merge_molo_transactions.sql',
    'sp_merge_stellar_booking_boats.sql',
    'sp_merge_stellar_booking_payments.sql',
    'sp_merge_stellar_bookings.sql',
    'sp_merge_stellar_customers.sql',
    'sp_merge_stellar_pos_items.sql',
    'sp_merge_stellar_pos_sales.sql',
    'sp_merge_stellar_style_boats.sql',
    'sp_merge_stellar_style_hourly_prices.sql',
    'sp_merge_stellar_style_prices.sql',
    'sp_merge_stellar_style_times.sql',
    'sp_merge_stellar_styles.sql',
]

def main():
    # Initialize Oracle client
    wallet_location = "./wallet"
    try:
        oracledb.init_oracle_client(
            lib_dir="/opt/oracle/instantclient",
            config_dir=wallet_location
        )
    except Exception as e:
        print(f"Note: Oracle client initialization: {e}")

    # Connect to database
    connection = oracledb.connect(
        user=config['database']['user'],
        password=config['database']['password'],
        dsn=config['database']['dsn'],
        config_dir=wallet_location,
        wallet_location=wallet_location,
        wallet_password=''
    )

    cursor = connection.cursor()
    
    success_count = 0
    error_count = 0
    errors = []
    
    print(f"Deploying {len(UPDATED_PROCEDURES)} updated stored procedures...\n")

    for proc_file in UPDATED_PROCEDURES:
        proc_path = os.path.join('stored_procedures', proc_file)
        
        if not os.path.exists(proc_path):
            print(f"❌ File not found: {proc_file}")
            error_count += 1
            errors.append((proc_file, "File not found"))
            continue
        
        try:
            # Read procedure file
            with open(proc_path, 'r') as f:
                sql = f.read()
            
            # Remove trailing / (SQL*Plus terminator)
            sql = sql.strip()
            if sql.endswith('/'):
                sql = sql[:-1].strip()
            
            # Execute CREATE OR REPLACE PROCEDURE
            cursor.execute(sql)
            
            # Check compilation status
            proc_name = proc_file.replace('.sql', '').upper()
            cursor.execute("""
                SELECT status 
                FROM user_objects 
                WHERE object_name = :name 
                AND object_type = 'PROCEDURE'
            """, name=proc_name)
            
            result = cursor.fetchone()
            if result and result[0] == 'VALID':
                print(f"✅ {proc_file}: VALID")
                success_count += 1
            else:
                status = result[0] if result else 'NOT FOUND'
                print(f"⚠️  {proc_file}: {status}")
                error_count += 1
                errors.append((proc_file, f"Status: {status}"))
                
                # Get compilation errors if invalid
                if status == 'INVALID':
                    cursor.execute("""
                        SELECT line, position, text
                        FROM user_errors
                        WHERE name = :name
                        AND type = 'PROCEDURE'
                        ORDER BY line, position
                    """, name=proc_name)
                    
                    for error_line in cursor.fetchall():
                        print(f"   Line {error_line[0]}: {error_line[2]}")
                    
        except Exception as e:
            print(f"❌ {proc_file}: ERROR - {str(e)[:100]}")
            error_count += 1
            errors.append((proc_file, str(e)[:100]))
    
    # Print summary
    print(f"\n{'='*70}")
    print(f"Deployment Summary:")
    print(f"  ✅ Successfully deployed: {success_count}/{len(UPDATED_PROCEDURES)}")
    print(f"  ❌ Errors: {error_count}/{len(UPDATED_PROCEDURES)}")
    
    if errors:
        print(f"\nErrors:")
        for proc_file, error in errors:
            print(f"  - {proc_file}: {error}")
    
    cursor.close()
    connection.close()
    
    # Exit with error code if any failures
    sys.exit(0 if error_count == 0 else 1)

if __name__ == "__main__":
    main()
