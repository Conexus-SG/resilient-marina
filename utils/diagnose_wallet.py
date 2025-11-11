#!/usr/bin/env python3
"""
Enhanced Oracle wallet diagnostic script
Specifically designed to troubleshoot ORA-28759 wallet file access issues
"""

import os
import sys
import stat
import subprocess
from pathlib import Path


def check_wallet_permissions(wallet_dir):
    """Check wallet directory and file permissions"""
    print(f"\n🔍 WALLET PERMISSION ANALYSIS")
    print("=" * 50)
    
    if not os.path.exists(wallet_dir):
        print(f"❌ Wallet directory does not exist: {wallet_dir}")
        return False
    
    print(f"📁 Wallet directory: {wallet_dir}")
    
    # Check directory permissions
    dir_stat = os.stat(wallet_dir)
    dir_perms = stat.filemode(dir_stat.st_mode)
    print(f"📂 Directory permissions: {dir_perms}")
    
    # Check if directory is readable
    if os.access(wallet_dir, os.R_OK):
        print("✅ Directory is readable")
    else:
        print("❌ Directory is NOT readable")
        return False
    
    # List and check each file
    wallet_files = os.listdir(wallet_dir)
    print(f"\n📄 Files in wallet directory: {len(wallet_files)}")
    
    required_files = [
        'tnsnames.ora',
        'sqlnet.ora', 
        'cwallet.sso',
        'ewallet.p12'  # Sometimes needed
    ]
    
    all_good = True
    
    for filename in wallet_files:
        filepath = os.path.join(wallet_dir, filename)
        if os.path.isfile(filepath):
            file_stat = os.stat(filepath)
            file_perms = stat.filemode(file_stat.st_mode)
            file_size = file_stat.st_size
            
            print(f"\n📄 {filename}")
            print(f"   Size: {file_size} bytes")
            print(f"   Permissions: {file_perms}")
            
            # Check if file is readable
            if os.access(filepath, os.R_OK):
                print(f"   ✅ Readable")
            else:
                print(f"   ❌ NOT readable")
                all_good = False
            
            # Check if it's a required file
            if filename in required_files:
                print(f"   ✅ Required file present")
                
                # Special checks for specific files
                if filename == 'cwallet.sso' and file_size == 0:
                    print(f"   ⚠️  WARNING: cwallet.sso is empty!")
                    all_good = False
                
                if filename in ['tnsnames.ora', 'sqlnet.ora']:
                    # Try to read first few lines
                    try:
                        with open(filepath, 'r') as f:
                            first_line = f.readline().strip()
                            if first_line:
                                print(f"   📝 First line: {first_line[:50]}...")
                            else:
                                print(f"   ⚠️  WARNING: File appears to be empty!")
                    except Exception as e:
                        print(f"   ❌ Cannot read file content: {e}")
                        all_good = False
    
    # Check for missing required files
    missing_files = []
    for req_file in required_files:
        if req_file not in wallet_files:
            missing_files.append(req_file)
    
    if missing_files:
        print(f"\n❌ Missing required files: {missing_files}")
        all_good = False
    
    return all_good


def check_tns_admin_setup():
    """Check TNS_ADMIN environment variable setup"""
    print(f"\n🔧 TNS_ADMIN CONFIGURATION")
    print("=" * 50)
    
    current_tns = os.environ.get('TNS_ADMIN')
    if current_tns:
        print(f"✅ TNS_ADMIN is set to: {current_tns}")
        
        if os.path.exists(current_tns):
            print(f"✅ TNS_ADMIN directory exists")
            return current_tns
        else:
            print(f"❌ TNS_ADMIN directory does not exist!")
            return None
    else:
        print(f"⚠️  TNS_ADMIN is not set")
        return None


def check_oracle_client():
    """Check Oracle client installation"""
    print(f"\n🔧 ORACLE CLIENT CHECK")
    print("=" * 50)
    
    # Check common Oracle client paths
    common_paths = [
        "/opt/oracle/instantclient",
        r"C:\oracle\instantclient_21_3",
        r"C:\oracle\instantclient_19_3", 
        r"C:\oracle\instantclient",
        "/usr/lib/oracle",
        "/usr/local/oracle"
    ]
    
    found_paths = []
    for path in common_paths:
        if os.path.exists(path):
            found_paths.append(path)
            print(f"✅ Found Oracle client at: {path}")
            
            # List contents
            try:
                contents = os.listdir(path)
                print(f"   Contents: {contents[:5]}...")  # Show first 5 items
            except:
                pass
    
    if not found_paths:
        print("⚠️  No Oracle Instant Client found in common locations")
        print("   You may need to install Oracle Instant Client")
    
    return found_paths


def fix_wallet_permissions(wallet_dir):
    """Attempt to fix wallet file permissions"""
    print(f"\n🔧 ATTEMPTING TO FIX PERMISSIONS")
    print("=" * 50)
    
    if not os.path.exists(wallet_dir):
        print(f"❌ Cannot fix permissions - directory doesn't exist: {wallet_dir}")
        return False
    
    try:
        # Try to make directory readable
        os.chmod(wallet_dir, 0o755)
        print(f"✅ Set directory permissions to 755")
        
        # Fix file permissions
        for filename in os.listdir(wallet_dir):
            filepath = os.path.join(wallet_dir, filename)
            if os.path.isfile(filepath):
                os.chmod(filepath, 0o644)
                print(f"✅ Set {filename} permissions to 644")
        
        return True
        
    except Exception as e:
        print(f"❌ Failed to fix permissions: {e}")
        print("   Try running as administrator/root")
        return False


def main():
    """Main diagnostic function"""
    print("🔍 ORACLE WALLET DIAGNOSTIC TOOL")
    print("=" * 60)
    print("Diagnosing ORA-28759: failure to open file")
    print("=" * 60)
    
    # Get wallet directory
    script_dir = os.path.dirname(os.path.abspath(__file__))
    wallet_dir = os.path.join(script_dir, "wallet_demo")
    
    print(f"🎯 Target wallet directory: {wallet_dir}")
    
    # Run checks
    print(f"\n1️⃣  Checking wallet directory and file permissions...")
    perms_ok = check_wallet_permissions(wallet_dir)
    
    print(f"\n2️⃣  Checking TNS_ADMIN configuration...")
    tns_admin = check_tns_admin_setup()
    
    print(f"\n3️⃣  Checking Oracle client installation...")
    oracle_paths = check_oracle_client()
    
    # Summary and recommendations
    print(f"\n" + "=" * 60)
    print("📋 DIAGNOSTIC SUMMARY")
    print("=" * 60)
    
    issues_found = []
    
    if not perms_ok:
        issues_found.append("Wallet file permission issues")
    
    if not tns_admin or tns_admin != wallet_dir:
        issues_found.append("TNS_ADMIN not properly configured")
    
    if not oracle_paths:
        issues_found.append("Oracle Instant Client not found")
    
    if issues_found:
        print("❌ ISSUES FOUND:")
        for i, issue in enumerate(issues_found, 1):
            print(f"   {i}. {issue}")
        
        print(f"\n🔧 RECOMMENDED FIXES:")
        
        if not perms_ok:
            print("   1. Fix wallet file permissions:")
            print(f"      chmod 755 {wallet_dir}")
            print(f"      chmod 644 {wallet_dir}/*")
            
            # Offer to fix automatically
            response = input("\n   Would you like me to try fixing permissions automatically? (y/n): ")
            if response.lower() == 'y':
                fix_wallet_permissions(wallet_dir)
        
        if not tns_admin or tns_admin != wallet_dir:
            print(f"   2. Set TNS_ADMIN environment variable:")
            print(f"      export TNS_ADMIN={wallet_dir}")
            print(f"      # Or in Python: os.environ['TNS_ADMIN'] = '{wallet_dir}'")
        
        if not oracle_paths:
            print("   3. Install Oracle Instant Client:")
            print("      - Download from Oracle website")
            print("      - Or use package manager (apt, yum, etc.)")
            
    else:
        print("✅ NO ISSUES FOUND - Wallet configuration appears correct")
        print("   The ORA-28759 error might be due to:")
        print("   - Network connectivity issues")
        print("   - Invalid wallet content")
        print("   - Wallet password issues")
    
    # Additional troubleshooting steps
    print(f"\n🔍 ADDITIONAL TROUBLESHOOTING:")
    print("   1. Verify wallet was downloaded correctly from Oracle Cloud")
    print("   2. Check if wallet password is required (ewallet.p12 vs cwallet.sso)")
    print("   3. Ensure database service name matches tnsnames.ora")
    print("   4. Test network connectivity to database host")
    
    return len(issues_found) == 0


if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)