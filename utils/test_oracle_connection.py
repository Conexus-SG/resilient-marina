#!/usr/bin/env python3
"""
Test script to verify Oracle database connection with wallet authentication.
This script tests the connection to Oracle Autonomous Database using wallet files.
"""

import sys
import os
import oracledb
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()


def test_oracle_connection(user: str, password: str, dsn: str) -> bool:
    """
    Test Oracle database connection with detailed error reporting.
    
    :param user: Database username
    :param password: Database password  
    :param dsn: Database service name/DSN
    :return: True if connection successful, False otherwise
    """
    connection = None
    cursor = None
    
    try:
        print("=" * 60)
        print("🧪 ORACLE DATABASE CONNECTION TEST")
        print("=" * 60)
        
        # Step 1: Set TNS_ADMIN FIRST (before any Oracle operations)
        wallet_dir = os.path.join(os.path.dirname(__file__), "wallet_demo")
        print(f"\n📁 Setting TNS_ADMIN to wallet directory: {wallet_dir}")
        
        if os.path.exists(wallet_dir):
            os.environ['TNS_ADMIN'] = wallet_dir
            print(f"✅ TNS_ADMIN set to: {wallet_dir}")
        else:
            print(f"❌ Wallet directory not found: {wallet_dir}")
            return False
        
        # Step 2: Check wallet directory and files
        print(f"\n📁 Checking wallet directory contents: {wallet_dir}")
        
        # List wallet files
        wallet_files = os.listdir(wallet_dir)
        print(f"📄 Wallet files found: {wallet_files}")
        
        # Check for required wallet files
        required_files = ['tnsnames.ora', 'sqlnet.ora', 'cwallet.sso']
        missing_files = []
        
        for req_file in required_files:
            if req_file in wallet_files:
                print(f"✅ {req_file} - Found")
            else:
                missing_files.append(req_file)
                print(f"❌ {req_file} - Missing")
        
        if missing_files:
            print(f"⚠️  Missing wallet files: {missing_files}")
            return False
        
        # Step 2: Initialize Oracle client
        print(f"\n🔧 Initializing Oracle Instant Client...")
        
        try:
            # Try different common paths for Oracle Instant Client
            client_paths = [
                "/opt/oracle/instantclient",
                r"C:\oracle\instantclient_21_3",
                r"C:\oracle\instantclient_19_3",
                r"C:\oracle\instantclient"
            ]
            
            client_initialized = False
            for path in client_paths:
                if os.path.exists(path):
                    try:
                        oracledb.init_oracle_client(lib_dir=path)
                        print(f"✅ Oracle Instant Client initialized from: {path}")
                        client_initialized = True
                        break
                    except Exception as e:
                        print(f"⚠️  Failed to initialize from {path}: {e}")
                        continue
            
            if not client_initialized:
                print("⚠️  No common Oracle client paths found, trying without lib_dir...")
                try:
                    oracledb.init_oracle_client()
                    print("✅ Oracle Instant Client initialized (thin mode)")
                except Exception as e:
                    print(f"⚠️  Oracle client initialization: {e}")
                    
        except Exception as e:
            if "already been initialized" in str(e):
                print("✅ Oracle client already initialized")
            else:
                print(f"❌ Oracle client initialization error: {e}")
                return False
        
        # Step 3: Test database connection
        print(f"\n🔌 Testing database connection...")
        print(f"   User: {user}")
        print(f"   DSN: {dsn}")
        print(f"   Connection string: {user}@{dsn}")
        
        connection = oracledb.connect(
            user=user,
            password=password,
            dsn=dsn
        )
        
        print("✅ Database connection successful!")
        
        # Step 4: Test basic database operations
        print(f"\n🔍 Testing basic database operations...")
        
        cursor = connection.cursor()
        
        # Test 1: Check database version
        cursor.execute("SELECT banner FROM v$version WHERE rownum = 1")
        version_result = cursor.fetchone()
        if version_result:
            print(f"✅ Database version: {version_result[0]}")
        
        # Test 2: Check current user
        cursor.execute("SELECT USER FROM dual")
        user_result = cursor.fetchone()
        if user_result:
            print(f"✅ Connected as user: {user_result[0]}")
        
        # Test 3: Check current timestamp
        cursor.execute("SELECT CURRENT_TIMESTAMP FROM dual")
        time_result = cursor.fetchone()
        if time_result:
            print(f"✅ Database timestamp: {time_result[0]}")
        
        # Test 4: Check if STG_ORDERS_TEST table exists
        cursor.execute("""
            SELECT COUNT(*) 
            FROM user_tables 
            WHERE table_name = 'STG_ORDERS_TEST'
        """)
        table_result = cursor.fetchone()
        if table_result and table_result[0] > 0:
            print("✅ STG_ORDERS_TEST table exists")
            
            # Get table structure
            cursor.execute("""
                SELECT column_name, data_type 
                FROM user_tab_columns 
                WHERE table_name = 'STG_ORDERS_TEST'
                ORDER BY column_id
            """)
            columns = cursor.fetchall()
            print("📋 Table structure:")
            for col_name, col_type in columns:
                print(f"   - {col_name}: {col_type}")
                
        else:
            print("⚠️  STG_ORDERS_TEST table not found")
        
        print(f"\n🎉 All connection tests passed successfully!")
        return True
        
    except oracledb.DatabaseError as e:
        error, = e.args
        print(f"\n❌ Database Error:")
        print(f"   Code: {error.code}")
        print(f"   Message: {error.message}")
        print(f"   Context: {error.context}")
        
        # Common error explanations
        if error.code == 1017:
            print("💡 This usually means invalid username/password")
        elif error.code == 12154:
            print("💡 This usually means TNS name could not be resolved")
        elif error.code == 12541:
            print("💡 This usually means no listener available")
        elif error.code == 17002:
            print("💡 This usually means IO error or network issue")
        
        return False
        
    except Exception as e:
        print(f"\n❌ Unexpected error: {e}")
        print(f"   Error type: {type(e).__name__}")
        return False
        
    finally:
        # Clean up connections
        if cursor:
            try:
                cursor.close()
                print("✅ Cursor closed")
            except:
                pass
                
        if connection:
            try:
                connection.close()
                print("✅ Connection closed")
            except:
                pass


def main():
    """Main function to run the connection test"""
    
    # Default connection parameters
    default_user = "OAX_USER"
    default_password = "NSAWDemo2025"  
    default_dsn = "oax7648725032_low"
    
    # Check for environment variables or command line args
    user = os.getenv('DB_USER', default_user)
    password = os.getenv('DB_PASSWORD', default_password)
    dsn = os.getenv('DB_DSN', default_dsn)
    
    # Allow command line arguments
    if len(sys.argv) >= 2:
        user = sys.argv[1]
    if len(sys.argv) >= 3:
        password = sys.argv[2]  
    if len(sys.argv) >= 4:
        dsn = sys.argv[3]
    
    print("🚀 Starting Oracle Connection Test")
    print(f"📅 Test started at: {oracledb.Timestamp.now()}")
    
    success = test_oracle_connection(user, password, dsn)
    
    if success:
        print("\n" + "=" * 60)
        print("✅ CONNECTION TEST PASSED - Database is accessible!")
        print("=" * 60)
        sys.exit(0)
    else:
        print("\n" + "=" * 60)
        print("❌ CONNECTION TEST FAILED - Please check configuration")
        print("=" * 60)
        print("\n🔧 Troubleshooting tips:")
        print("1. Verify wallet files are in the wallet_demo directory")
        print("2. Check database credentials (user/password)")
        print("3. Ensure Oracle Instant Client is installed")
        print("4. Verify network connectivity to the database")
        print("5. Check TNS_ADMIN environment variable points to wallet")
        sys.exit(1)


if __name__ == "__main__":
    main()