#!/usr/bin/env python3
"""Test database connection for deployment"""

import oracledb
import json

# Read config
with open('config.json') as f:
    config = json.load(f)

# Initialize Oracle client
try:
    oracledb.init_oracle_client(lib_dir="/opt/oracle/instantclient")
except Exception as e:
    print(f"Oracle client: {e}")

# Connect to database
wallet_location = "./wallet_demo"

print("Connecting to database...")
connection = oracledb.connect(
    user=config['database']['user'],
    password=config['database']['password'],
    dsn=config['database']['dsn'],
    config_dir=wallet_location,
    wallet_location=wallet_location,
    wallet_password=''
)

print("✅ Connected successfully!")

cursor = connection.cursor()
cursor.execute("SELECT COUNT(*) FROM user_objects WHERE object_type = 'PROCEDURE'")
count = cursor.fetchone()[0]
print(f"Found {count} procedures in database")

cursor.close()
connection.close()
