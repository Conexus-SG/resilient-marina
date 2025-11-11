#!/usr/bin/env python3
"""
Simple Oracle connection test runner
"""

import argparse
from test_oracle_connection import test_oracle_connection


def main():
    parser = argparse.ArgumentParser(
        description="Test Oracle database connection with wallet"
    )
    parser.add_argument(
        "--user", 
        default="OAX_USER", 
        help="Database username"
    )
    parser.add_argument(
        "--password", 
        default="NSAWDemo2025", 
        help="Database password"
    )
    parser.add_argument(
        "--dsn", 
        default="oax5007253621_low", 
        help="Database DSN/service name"
    )
    
    args = parser.parse_args()
    
    success = test_oracle_connection(args.user, args.password, args.dsn)
    
    if not success:
        exit(1)


if __name__ == "__main__":
    main()