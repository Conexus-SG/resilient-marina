"""
Execute SP_RUN_ALL_MOLO_STELLAR_MERGES stored procedure.
"""
import oracledb
import json

# Load configuration from config.json
with open('config.json') as f:
    config = json.load(f)['database']

# Database configuration
DB_USER = config['user']
DB_PASSWORD = config['password']
DB_DSN = config['dsn']
WALLET_LOCATION = './wallet_demo'
WALLET_PASSWORD = ''


def init_oracle_client():
    """Initialize Oracle client in thick mode."""
    try:
        oracledb.init_oracle_client(
            lib_dir="/opt/oracle/instantclient",
            config_dir=WALLET_LOCATION
        )
        print("✅ Oracle Instant Client initialized")
    except Exception as e:
        print(f"Oracle client already initialized: {e}")


def main():
    """Execute the merge procedure."""
    print("="*70)
    print("Execute MOLO & Stellar Merges: STG_* → DW_*")
    print("="*70)
    
    # Initialize Oracle client
    init_oracle_client()
    
    # Connect to database
    print(f"\n🔌 Connecting to {DB_DSN}...")
    try:
        connection = oracledb.connect(
            user=DB_USER,
            password=DB_PASSWORD,
            dsn=DB_DSN,
            config_dir=WALLET_LOCATION,
            wallet_location=WALLET_LOCATION,
            wallet_password=WALLET_PASSWORD
        )
        print("✅ Connected successfully\n")
    except Exception as e:
        print(f"❌ Connection failed: {e}")
        return
    
    cursor = connection.cursor()
    
    # Enable DBMS_OUTPUT
    cursor.callproc("dbms_output.enable")
    
    print("▶️  Executing SP_RUN_ALL_MOLO_STELLAR_MERGES...\n")
    
    try:
        # Execute the merge procedure
        cursor.callproc("SP_RUN_ALL_MOLO_STELLAR_MERGES")
        
        # Fetch DBMS_OUTPUT
        status_var = cursor.var(int)
        line_var = cursor.var(str)
        
        while True:
            cursor.callproc("dbms_output.get_line", (line_var, status_var))
            if status_var.getvalue() != 0:
                break
            print(line_var.getvalue())
        
        connection.commit()
        print("\n✅ All merges completed successfully!")
        
    except Exception as e:
        print(f"\n❌ Error executing merges: {e}")
        connection.rollback()
    
    cursor.close()
    connection.close()
    print("="*70)


if __name__ == '__main__':
    main()
