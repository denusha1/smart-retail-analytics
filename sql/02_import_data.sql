-- ============================================================================
-- Smart Retail Analytics - Data Import Script
-- ============================================================================
-- This script loads enriched CSV data into the transactions table
-- Source: data/processed/retail_enriched.csv
-- ============================================================================

USE smart_retail;

-- Step 1: Load Transaction Data from CSV
-- ============================================================================
-- NOTE: Adjust file path based on your system
-- For macOS/Linux: Use full path like /path/to/retail_enriched.csv
-- For Windows: Use path with backslashes or single quotes around path
-- Make sure MySQL has FILE permissions

-- Option 1: Direct LOAD DATA INFILE (requires file system access and permissions)
-- ============================================================================
-- LOAD DATA INFILE '/Users/denushathavaruban/Desktop/smart-retail-analyics/smart-retail-analytics/data/processed/retail_enriched.csv'
-- INTO TABLE transactions
-- FIELDS TERMINATED BY ','
-- ENCLOSED BY '"'
-- LINES TERMINATED BY '\n'
-- IGNORE 1 ROWS
-- (transaction_date, branch_id, product_name, category, customer_type, customer_segment,
--  quantity_sold, unit_price, total_sales, discount_percent, revenue, profit_margin_percent,
--  estimated_profit, profit_margin, sales_performance, year, month, day_of_week);

-- Option 2: Alternative using MySQL Workbench or direct Python import
-- ============================================================================
-- RECOMMENDED: Use Python script (see import_data.py in root folder)
-- This provides better error handling and logging

-- Python Import Command:
-- python3 << 'EOF'
-- import pandas as pd
-- from sqlalchemy import create_engine
-- 
-- # Connect to MySQL
-- engine = create_engine('mysql+pymysql://root:password@localhost/smart_retail')
-- 
-- # Read enriched CSV
-- df = pd.read_csv('data/processed/retail_enriched.csv')
-- 
-- # Insert into transactions table
-- df.to_sql('transactions', con=engine, if_exists='append', index=False)
-- 
-- print(f"✓ Imported {len(df)} transactions successfully")
-- EOF

-- Step 2: Verify Data Import
-- ============================================================================
-- Run after importing data to verify:

-- Count total records
SELECT COUNT(*) as total_transactions FROM transactions;

-- Check date range
SELECT MIN(transaction_date) as earliest_date, MAX(transaction_date) as latest_date FROM transactions;

-- Check branch distribution
SELECT branch_id, COUNT(*) as transaction_count, SUM(revenue) as total_revenue 
FROM transactions 
GROUP BY branch_id 
ORDER BY total_revenue DESC;

-- Check category distribution
SELECT category, COUNT(*) as count, SUM(revenue) as total_revenue 
FROM transactions 
GROUP BY category 
ORDER BY total_revenue DESC;

-- Check data quality
SELECT 
    COUNT(*) as total_records,
    SUM(CASE WHEN transaction_date IS NULL THEN 1 ELSE 0 END) as missing_dates,
    SUM(CASE WHEN revenue IS NULL THEN 1 ELSE 0 END) as missing_revenue,
    SUM(CASE WHEN quantity_sold <= 0 THEN 1 ELSE 0 END) as invalid_quantities,
    SUM(CASE WHEN revenue < 0 THEN 1 ELSE 0 END) as negative_revenues
FROM transactions;

-- ============================================================================
-- Next Steps:
-- 1. Populate products table: INSERT INTO products SELECT DISTINCT product_name, category, unit_price, profit_margin_percent FROM transactions;
-- 2. Populate customers table: INSERT INTO customers (customer_type, customer_segment) SELECT DISTINCT customer_type, customer_segment FROM transactions;
-- 3. Run analysis queries from other SQL files
-- ============================================================================
