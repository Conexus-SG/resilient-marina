"""
Simple deployment: Execute stored procedures SQL file.
"""
import oracledb
import json
import sys

# Load config
with open('config.json') as f:
    config = json.load(f)['database']

# Wallet location (hardcoded for now)
WALLET_LOCATION = './wallet'

# Initialize Oracle client
try:
    oracledb.init_oracle_client(
        lib_dir="/opt/oracle/instantclient",
        config_dir=WALLET_LOCATION
    )
except:
    pass  # Already initialized

print("="*70)
print("Deploying Stored Procedures")
print("="*70)

# Connect
print(f"\nConnecting to {config['dsn']}...")
conn = oracledb.connect(
    user=config['user'],
    password=config['password'],
    dsn=config['dsn'],
    config_dir=WALLET_LOCATION,
    wallet_location=WALLET_LOCATION,
    wallet_password=''
)
print("✅ Connected\n")

cursor = conn.cursor()

# Read and execute SQL file
sql_file = 'stored_procedures/deploy_all_procedures.sql'
print(f"Reading {sql_file}...")

with open(sql_file) as f:
    sql = f.read()

# Split by / and execute each CREATE statement
statements = []
current = []

for line in sql.split('\n'):
    if line.strip().startswith('--') or line.strip().startswith('PROMPT'):
        continue
    if line.strip() == '/':
        if current:
            statements.append('\n'.join(current))
            current = []
    else:
        current.append(line)

print(f"Found {len(statements)} procedures to deploy\n")

success_count = 0
error_count = 0

for i, stmt in enumerate(statements, 1):
    if not stmt.strip():
        continue
    
    # Extract procedure name from CREATE statement
    try:
        name_line = [l for l in stmt.split('\n') if 'PROCEDURE' in l.upper()][0]
        proc_name = name_line.split('PROCEDURE')[1].split()[0].strip()
    except:
        proc_name = f"Statement {i}"
    
    print(f"[{i}/{len(statements)}] Deploying {proc_name}...", end=" ")
    
    try:
        cursor.execute(stmt)
        print("✅")
        success_count += 1
    except Exception as e:
        print(f"❌")
        print(f"   Error: {str(e)[:100]}")
        error_count += 1

conn.commit()
cursor.close()
conn.close()

print("\n" + "="*70)
print(f"✅ Deployed: {success_count}")
if error_count > 0:
    print(f"❌ Errors: {error_count}")
print("="*70)

if success_count > 0:
    print("\nTo execute merges, run:")
    print("  python3 run_merges.py")

sys.exit(0 if error_count == 0 else 1)
