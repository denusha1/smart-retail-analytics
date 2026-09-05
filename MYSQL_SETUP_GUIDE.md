# MySQL Database Setup Guide
## Smart Retail Analytics Project

This guide walks you through setting up the MySQL database for the Smart Retail Analytics project.

---

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Installation](#installation)
3. [Setup Steps](#setup-steps)
4. [Data Import](#data-import)
5. [Verification](#verification)
6. [Running Queries](#running-queries)
7. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required Software
- MySQL Server (5.7 or higher recommended; 8.0+ for advanced features)
- MySQL Command Line Client
- Python 3.9+ (already set up in your environment)

### Required Python Packages
```bash
pip install pymysql sqlalchemy pandas
```

---

## Installation

### macOS (using Homebrew)

```bash
# Install MySQL
brew install mysql

# Start MySQL service
brew services start mysql

# Verify installation
mysql --version
```

### macOS (using Docker - Alternative)

```bash
# Pull MySQL image
docker pull mysql:8.0

# Run container
docker run --name smart-retail-db \
  -e MYSQL_ROOT_PASSWORD=password \
  -p 3306:3306 \
  -d mysql:8.0
```

### macOS (using DMG Installer)

1. Download MySQL Community Server from https://dev.mysql.com/downloads/mysql/
2. Install using the `.dmg` installer
3. Follow the installation wizard
4. Set root password during setup
5. Verify with: `mysql -u root -p`

### Linux (Ubuntu/Debian)

```bash
# Install MySQL
sudo apt update
sudo apt install mysql-server

# Secure installation
sudo mysql_secure_installation

# Start service
sudo systemctl start mysql
```

### Windows

1. Download MySQL installer from https://dev.mysql.com/downloads/windows/installer/
2. Run the installer
3. Choose "Development Default" setup type
4. Complete the configuration wizard
5. Verify in Command Prompt: `mysql -u root -p`

---

## Setup Steps

### Step 1: Start MySQL Service

```bash
# macOS with Homebrew
brew services start mysql

# macOS with Docker
docker start smart-retail-db

# Linux
sudo systemctl start mysql

# Windows
# MySQL runs as a service automatically
```

### Step 2: Verify MySQL is Running

```bash
# Test connection
mysql -u root -p
# Enter password (if set)
# You should see: mysql>
# Type: EXIT to close
```

### Step 3: Create Database and Tables

Option A: Using MySQL Command Line

```bash
# Login to MySQL
mysql -u root -p

# Run the setup script
source ~/Desktop/smart-retail-analyics/smart-retail-analytics/sql/01_database_setup.sql;

# Verify database created
SHOW DATABASES;
USE smart_retail;
SHOW TABLES;
```

Option B: Using Python Script (Recommended)

```bash
cd ~/Desktop/smart-retail-analyics/smart-retail-analytics

# First ensure database setup
python3 << 'EOF'
import subprocess
import os

sql_file = "sql/01_database_setup.sql"
os.system(f"mysql -u root -p < {sql_file}")
EOF
```

### Step 4: Verify Database Setup

```bash
mysql -u root -p smart_retail

# Check tables
SHOW TABLES;
# Should show: branches, products, customers, transactions

# Check branches
SELECT * FROM branches;
```

---

## Data Import

### Method 1: Using Python Script (RECOMMENDED)

```bash
cd ~/Desktop/smart-retail-analyics/smart-retail-analytics

# Run the import script
python3 import_data.py

# Expected output:
# ✓ Connected to MySQL
# ✓ Loaded 28 rows × 23 columns
# ✓ Successfully imported 28 transactions
```

### Method 2: Direct CSV Upload in MySQL

```bash
mysql -u root -p smart_retail << 'EOF'

LOAD DATA INFILE '/Users/denushathavaruban/Desktop/smart-retail-analyics/smart-retail-analytics/data/processed/retail_enriched.csv'
INTO TABLE transactions
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

EOF
```

### Method 3: Manual SQL INSERT

```bash
# Open MySQL
mysql -u root -p smart_retail

# Insert sample data
INSERT INTO transactions (
    transaction_date, branch_id, product_name, category,
    customer_type, customer_segment, quantity_sold, unit_price,
    total_sales, discount_percent, revenue, profit_margin_percent,
    estimated_profit, profit_margin, sales_performance, year, month, day_of_week
)
VALUES
('2024-01-01', 'S001', 'Laptop', 'Electronics', 'Online', 'Premium Online',
 2, 89999, 179998, 0.00, 179998, 30, 53999.4, 30.0, 'Very High', 2024, 1, 'Monday');
```

---

## Verification

### Verify Data Import

```bash
mysql -u root -p smart_retail << 'EOF'

-- Check row count
SELECT COUNT(*) as total_transactions FROM transactions;

-- Should show: 28 (for sample data)

-- Check date range
SELECT MIN(transaction_date) as first_date, MAX(transaction_date) as last_date 
FROM transactions;

-- Check branch distribution
SELECT branch_id, COUNT(*) as sales_count, SUM(revenue) as branch_revenue
FROM transactions
GROUP BY branch_id
ORDER BY branch_revenue DESC;

-- Verify data quality
SELECT 
    COUNT(*) as total_records,
    SUM(CASE WHEN transaction_date IS NULL THEN 1 ELSE 0 END) as missing_dates,
    SUM(CASE WHEN revenue < 0 THEN 1 ELSE 0 END) as negative_revenue,
    SUM(CASE WHEN quantity_sold <= 0 THEN 1 ELSE 0 END) as invalid_quantity
FROM transactions;

EOF
```

---

## Running Queries

### Quick Analysis Queries

```bash
# Connect to database
mysql -u root -p smart_retail

# Top 10 products by revenue
SOURCE sql/product_analysis.sql;

# Customer analysis
SOURCE sql/customer_analysis.sql;

# Sales analysis
SOURCE sql/sales_analysis.sql;
```

### Sample Queries

```sql
-- Total Revenue by Category
SELECT category, SUM(revenue) as total_revenue
FROM transactions
GROUP BY category
ORDER BY total_revenue DESC;

-- Top 5 Branches
SELECT branch_id, COUNT(*) as sales, SUM(revenue) as total_revenue
FROM transactions
GROUP BY branch_id
ORDER BY total_revenue DESC
LIMIT 5;

-- Revenue Trend
SELECT transaction_date, SUM(revenue) as daily_revenue
FROM transactions
GROUP BY transaction_date
ORDER BY transaction_date;
```

---

## Troubleshooting

### Issue 1: MySQL Service Not Starting

**macOS (Homebrew):**
```bash
# Check if running
brew services list

# Restart
brew services restart mysql

# View logs
tail -f /usr/local/var/log/mysql/error.log
```

**macOS (Docker):**
```bash
# Check container
docker ps | grep smart-retail-db

# Restart
docker restart smart-retail-db

# View logs
docker logs smart-retail-db
```

### Issue 2: Connection Refused

```bash
# Verify MySQL is listening
lsof -i :3306

# Start MySQL explicitly
mysql.server start

# Or use Homebrew
brew services start mysql
```

### Issue 3: "Access denied for user 'root'"

```bash
# Reset root password
mysql -u root
ALTER USER 'root'@'localhost' IDENTIFIED BY 'new_password';
FLUSH PRIVILEGES;
```

### Issue 4: "File not found" for CSV import

```bash
# Verify file exists
ls -la data/processed/retail_enriched.csv

# Check MySQL file permissions
mysql -u root -p -e "SHOW VARIABLES LIKE 'secure_file_priv';"

# If restricted, use Python import method instead
python3 import_data.py
```

### Issue 5: "Unknown database" error

```bash
# Verify database exists
mysql -u root -p -e "SHOW DATABASES;"

# If not found, create it
mysql -u root -p < sql/01_database_setup.sql
```

---

## Next Steps

1. ✅ MySQL installed and running
2. ✅ Database created (smart_retail)
3. ✅ Tables created (branches, transactions)
4. ✅ Data imported (28 sample transactions)
5. **→ Run analysis queries (sql/ folder)**
6. **→ Build Power BI dashboard (connect to MySQL)**
7. **→ Create automated reports**

---

## Connection String for Tools

### Python (SQLAlchemy)
```python
from sqlalchemy import create_engine

engine = create_engine('mysql+pymysql://root:password@localhost/smart_retail')
df = pd.read_sql('SELECT * FROM transactions', con=engine)
```

### Power BI
```
Server: localhost
Port: 3306
Database: smart_retail
Username: root
Authentication: Database (MySQL)
```

### DBeaver (Database GUI)
1. New Database Connection → MySQL
2. Server: localhost
3. Port: 3306
4. Database: smart_retail
5. Username: root
6. Password: (your password)
7. Test Connection

---

## Support

For issues or questions:
1. Check MySQL error logs: `/usr/local/var/log/mysql/error.log`
2. Verify file permissions
3. Ensure ports are not in use: `lsof -i :3306`
4. Check firewall settings (if connecting remotely)

---

**Last Updated:** 2024-01-15
**Project:** Smart Retail Analytics
**Status:** Database Setup Complete ✅
