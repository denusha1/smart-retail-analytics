#!/usr/bin/env python3
"""
Smart Retail Analytics - MySQL Data Import Script
==================================================
This script loads enriched CSV data into a MySQL database.
Requires: mysql-connector-python or pymysql library
"""

import pandas as pd
import sys
from pathlib import Path

def install_required_packages():
    """Install required packages if not already installed"""
    try:
        import sqlalchemy
        from pymysql import connect
    except ImportError:
        print("Installing required packages...")
        import subprocess
        subprocess.check_call([sys.executable, "-m", "pip", "install", "pymysql", "sqlalchemy"])

def load_data_to_mysql(
    csv_file='data/processed/retail_enriched.csv',
    host='localhost',
    user='root',
    password='',
    database='smart_retail',
    table='transactions'
):
    """
    Load CSV data into MySQL database
    
    Args:
        csv_file: Path to enriched CSV file
        host: MySQL host address
        user: MySQL username
        password: MySQL password
        database: Target database name
        table: Target table name
    """
    print(f"\n{'='*80}")
    print(f"SMART RETAIL ANALYTICS - MYSQL DATA IMPORT")
    print(f"{'='*80}")
    
    # Check if CSV file exists
    csv_path = Path(csv_file)
    if not csv_path.exists():
        print(f"❌ ERROR: File not found: {csv_file}")
        return False
    
    print(f"\n✓ CSV file found: {csv_file}")
    
    try:
        # Load CSV
        print(f"\n📥 Loading CSV data...")
        df = pd.read_csv(csv_file)
        print(f"✓ Loaded {len(df)} rows × {len(df.columns)} columns")
        
        # Show data preview
        print(f"\n📊 Data Preview (first 5 rows):")
        print(df.head())
        
        # Connect to MySQL
        print(f"\n🔌 Connecting to MySQL database...")
        from sqlalchemy import create_engine
        
        # Create connection string
        connection_string = f"mysql+pymysql://{user}:{password}@{host}/{database}"
        engine = create_engine(connection_string)
        
        # Test connection
        with engine.connect() as connection:
            print(f"✓ Connected to MySQL @ {host}")
            print(f"✓ Database: {database}")
        
        # Insert data
        print(f"\n📤 Importing data into table '{table}'...")
        df.to_sql(table, con=engine, if_exists='append', index=False, chunksize=100)
        print(f"✓ Successfully imported {len(df)} transactions")
        
        # Verify import
        print(f"\n✅ VERIFICATION")
        print(f"{'-'*80}")
        
        with engine.connect() as connection:
            # Count records
            result = connection.execute(f"SELECT COUNT(*) as row_count FROM {table}")
            row_count = result.fetchone()[0]
            print(f"✓ Total records in {table}: {row_count}")
            
            # Date range
            result = connection.execute(
                f"SELECT MIN(transaction_date) as earliest, MAX(transaction_date) as latest FROM {table}"
            )
            earliest, latest = result.fetchone()
            print(f"✓ Date range: {earliest} to {latest}")
            
            # Branch count
            result = connection.execute(
                f"SELECT COUNT(DISTINCT branch_id) as branches FROM {table}"
            )
            branches = result.fetchone()[0]
            print(f"✓ Branches: {branches}")
            
            # Category count
            result = connection.execute(
                f"SELECT COUNT(DISTINCT category) as categories FROM {table}"
            )
            categories = result.fetchone()[0]
            print(f"✓ Product categories: {categories}")
            
            # Revenue
            result = connection.execute(
                f"SELECT SUM(revenue) as total_revenue FROM {table}"
            )
            total_revenue = result.fetchone()[0]
            print(f"✓ Total revenue: ₹{total_revenue:,.0f}")
        
        print(f"\n{'='*80}")
        print(f"✅ IMPORT SUCCESSFUL")
        print(f"{'='*80}")
        print(f"\nNext steps:")
        print(f"1. Run MySQL analysis queries from sql/ folder")
        print(f"2. Execute sales_analysis.sql for revenue/profit insights")
        print(f"3. Execute product_analysis.sql for product performance")
        print(f"4. Execute customer_analysis.sql for customer insights")
        
        return True
        
    except Exception as e:
        print(f"\n❌ ERROR during import: {str(e)}")
        print(f"\nTroubleshooting:")
        print(f"1. Verify MySQL is running: mysql -u {user} -p")
        print(f"2. Check database exists: CREATE DATABASE {database};")
        print(f"3. Run setup SQL first: mysql -u {user} -p {database} < sql/01_database_setup.sql")
        print(f"4. Verify CSV path: {csv_file}")
        return False

def main():
    """Main entry point"""
    print(f"\nSmart Retail Analytics - MySQL Data Import Tool")
    print(f"Supported operating systems: Linux, macOS, Windows")
    
    # Ensure packages are installed
    install_required_packages()
    
    # Configuration
    config = {
        'csv_file': 'data/processed/retail_enriched.csv',
        'host': 'localhost',
        'user': 'root',
        'password': '',  # Change if needed
        'database': 'smart_retail',
        'table': 'transactions'
    }
    
    print(f"\n{'─'*80}")
    print(f"Configuration:")
    print(f"{'─'*80}")
    print(f"MySQL Host: {config['host']}")
    print(f"MySQL User: {config['user']}")
    print(f"Database: {config['database']}")
    print(f"Table: {config['table']}")
    print(f"CSV Source: {config['csv_file']}")
    
    # Ask for customization
    print(f"\nNote: Edit this script to change MySQL credentials if needed.")
    
    # Run import
    success = load_data_to_mysql(**config)
    
    return 0 if success else 1

if __name__ == '__main__':
    sys.exit(main())
