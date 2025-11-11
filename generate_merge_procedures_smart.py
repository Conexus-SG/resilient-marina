"""
Generate MERGE procedures with actual column names from database schema.
"""
import oracledb
import json

# Load config
with open('config.json') as f:
    config = json.load(f)['database']

WALLET_LOCATION = './wallet_demo'

# Initialize
try:
    oracledb.init_oracle_client(
        lib_dir="/opt/oracle/instantclient",
        config_dir=WALLET_LOCATION
    )
except Exception:
    pass

# Connect
print("Connecting to database...")
conn = oracledb.connect(
    user=config['user'],
    password=config['password'],
    dsn=config['dsn'],
    config_dir=WALLET_LOCATION,
    wallet_location=WALLET_LOCATION,
    wallet_password=''
)

cursor = conn.cursor()

# MOLO and Stellar tables
MOLO_TABLES = [
    'ACCOUNTS', 'BOATS', 'BOAT_TYPES', 'CITIES', 'COMPANIES',
    'CONTACT_AUTO_CHARGE', 'CONTACTS', 'CONTACT_TYPES', 'COUNTRIES',
    'INSURANCE_STATUS', 'INVOICE_ITEMS', 'INVOICES', 'INVOICE_STATUS',
    'INVOICE_TYPES', 'ITEM_CHARGE_METHODS', 'ITEM_MASTERS', 
    'MARINA_LOCATIONS', 'PAYMENT_METHODS', 'PHONE_TYPES', 'PIERS',
    'POWER_NEEDS', 'RECORD_STATUS', 'RESERVATIONS', 'RESERVATION_STATUS',
    'RESERVATION_TYPES', 'SEASONAL_CHARGE_METHODS', 'SEASONAL_PRICES',
    'SLIPS', 'SLIP_TYPES', 'STATEMENTS_PREFERENCE', 'TRANSACTION_METHODS',
    'TRANSACTIONS', 'TRANSACTION_TYPES', 'TRANSIENT_CHARGE_METHODS',
    'TRANSIENT_PRICES'
]

STELLAR_TABLES = [
    'CUSTOMERS', 'LOCATIONS', 'SEASONS', 'ACCESSORIES', 'ACCESSORY_OPTIONS',
    'ACCESSORY_TIERS', 'AMENITIES', 'CATEGORIES', 'HOLIDAYS',
    'BOOKINGS', 'BOOKING_BOATS', 'BOOKING_PAYMENTS', 'BOOKING_ACCESSORIES',
    'STYLE_GROUPS', 'STYLES', 'STYLE_BOATS', 'CUSTOMER_BOATS',
    'SEASON_DATES', 'STYLE_HOURLY_PRICES', 'STYLE_TIMES', 'STYLE_PRICES',
    'CLUB_TIERS', 'COUPONS', 'POS_ITEMS', 'POS_SALES', 'FUEL_SALES',
    'WAITLISTS', 'CLOSED_DATES', 'BLACKLISTS'
]


def get_stg_columns(table_name, system):
    """Get column list from STG table (excludes DW_ID, LAST_IMPORTED, LAST_UPDATED)."""
    stg_table = f"STG_{system}_{table_name}"
    
    cursor.execute(f"""
        SELECT column_name, data_type
        FROM user_tab_columns
        WHERE table_name = '{stg_table}'
        ORDER BY column_id
    """)
    
    columns = []
    pk_column = None
    
    for row in cursor:
        col_name = row[0]
        columns.append(col_name)
        
        # Detect primary key - usually ID or <TABLE>_ID or USER_ID for Stellar
        if col_name == 'ID':
            pk_column = 'ID'
        elif col_name == 'USER_ID' and system == 'STELLAR':
            pk_column = 'USER_ID'
        elif col_name.endswith('_ID') and len(col_name.split('_')) == 2 and not pk_column:
            pk_column = col_name
    
    # Fallback: use first column
    if not pk_column and columns:
        pk_column = columns[0]
        
    return columns, pk_column


def generate_merge_with_columns(system, table_name):
    """Generate MERGE procedure with explicit column mappings."""
    stg_table = f"STG_{system}_{table_name}"
    dw_table = f"DW_{system}_{table_name}"
    proc_name = f"SP_MERGE_{system}_{table_name}"
    
    # Get columns from staging table
    stg_columns, pk_column = get_stg_columns(table_name, system)
    
    if not stg_columns:
        return f"-- ERROR: No columns found for {stg_table}\n"
    
    # Build UPDATE SET clause (all columns except PK)
    update_cols = [c for c in stg_columns if c != pk_column]
    update_set = ',\n            '.join([f"tgt.{col} = src.{col}" for col in update_cols])
    update_set += ',\n            tgt.DW_LAST_UPDATED = SYSTIMESTAMP'
    
    # Build INSERT column list and VALUES list
    insert_cols = ', '.join(stg_columns)
    insert_vals = ', '.join([f"src.{col}" for col in stg_columns])
    
    sql = f"""
-- ============================================================================
-- Merge {stg_table} to {dw_table}
-- ============================================================================
CREATE OR REPLACE PROCEDURE {proc_name}
IS
    v_merged NUMBER := 0;
BEGIN
    MERGE INTO {dw_table} tgt
    USING {stg_table} src
    ON (tgt.{pk_column} = src.{pk_column})
    WHEN MATCHED THEN
        UPDATE SET
            {update_set}
    WHEN NOT MATCHED THEN
        INSERT (
            {insert_cols},
            DW_LAST_INSERTED,
            DW_LAST_UPDATED
        )
        VALUES (
            {insert_vals},
            SYSTIMESTAMP,
            SYSTIMESTAMP
        );
    
    v_merged := SQL%ROWCOUNT;
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('{dw_table}: Merged ' || v_merged || ' records');
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error in {proc_name}: ' || SQLERRM);
        RAISE;
END {proc_name};
/
"""
    return sql


# Generate procedures
print("\nGenerating MOLO merge procedures...")
molo_procs = []
for table in MOLO_TABLES:
    print(f"  {table}...", end=" ")
    try:
        proc_sql = generate_merge_with_columns('MOLO', table)
        molo_procs.append(proc_sql)
        
        # Save individual file
        with open(f"stored_procedures/sp_merge_molo_{table.lower()}.sql", 'w') as f:
            f.write(proc_sql)
        print("✅")
    except Exception as e:
        print(f"❌ {e}")

print("\nGenerating Stellar merge procedures...")
stellar_procs = []
for table in STELLAR_TABLES:
    print(f"  {table}...", end=" ")
    try:
        proc_sql = generate_merge_with_columns('STELLAR', table)
        stellar_procs.append(proc_sql)
        
        # Save individual file
        with open(f"stored_procedures/sp_merge_stellar_{table.lower()}.sql", 'w') as f:
            f.write(proc_sql)
        print("✅")
    except Exception as e:
        print(f"❌ {e}")

# Generate master procedure (same as before)
print("\nGenerating master procedure...")
molo_calls = '\n    '.join([f"SP_MERGE_MOLO_{t};" for t in MOLO_TABLES])
stellar_calls = '\n    '.join([f"SP_MERGE_STELLAR_{t};" for t in STELLAR_TABLES])

master_proc = f"""
-- ============================================================================
-- Master Procedure: Execute All MOLO and Stellar Merges
-- ============================================================================
CREATE OR REPLACE PROCEDURE SP_RUN_ALL_MOLO_STELLAR_MERGES
IS
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
    v_duration NUMBER;
BEGIN
    v_start_time := SYSTIMESTAMP;
    
    DBMS_OUTPUT.PUT_LINE('========================================');
    DBMS_OUTPUT.PUT_LINE('STARTING MERGE: STG_* -> DW_* Tables');
    DBMS_OUTPUT.PUT_LINE('========================================');
    
    -- MOLO Merges
    DBMS_OUTPUT.PUT_LINE('--- Processing MOLO Tables ---');
    {molo_calls}
    
    -- Stellar Merges
    DBMS_OUTPUT.PUT_LINE('--- Processing Stellar Tables ---');
    {stellar_calls}
    
    v_end_time := SYSTIMESTAMP;
    v_duration := EXTRACT(SECOND FROM (v_end_time - v_start_time));
    
    DBMS_OUTPUT.PUT_LINE('========================================');
    DBMS_OUTPUT.PUT_LINE('ALL MERGES COMPLETED');
    DBMS_OUTPUT.PUT_LINE('Duration: ' || ROUND(v_duration, 2) || ' seconds');
    DBMS_OUTPUT.PUT_LINE('========================================');
    
    COMMIT;
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLERRM);
        RAISE;
END SP_RUN_ALL_MOLO_STELLAR_MERGES;
/
"""

with open('stored_procedures/sp_run_all_merges.sql', 'w') as f:
    f.write(master_proc)

# Generate combined deployment file
print("Generating deployment file...")
with open('stored_procedures/deploy_all_procedures.sql', 'w') as f:
    f.write("SET SERVEROUTPUT ON SIZE UNLIMITED;\n\n")
    f.write("-- MOLO Merge Procedures\n")
    for proc in molo_procs:
        f.write(proc)
        f.write("\n")
    
    f.write("\n-- Stellar Merge Procedures\n")
    for proc in stellar_procs:
        f.write(proc)
        f.write("\n")
    
    f.write("\n-- Master Procedure\n")
    f.write(master_proc)

print("\n" + "="*70)
print(f"✅ Generated {len(MOLO_TABLES) + len(STELLAR_TABLES) + 1} procedures")
print("="*70)
print("\nTo deploy:")
print("  python3 deploy_procedures_simple.py")
print("\nTo execute merges:")
print("  python3 run_merges.py")

cursor.close()
conn.close()
