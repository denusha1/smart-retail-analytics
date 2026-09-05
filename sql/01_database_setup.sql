-- ============================================================================
-- Smart Retail Analytics - Database Setup Script
-- ============================================================================
-- This script creates the database schema for Smart Retail Analytics
-- Database: smart_retail
-- Tables: customers, products, branches, transactions
-- ============================================================================

-- Step 1: Create Database
-- ============================================================================
CREATE DATABASE IF NOT EXISTS smart_retail;
USE smart_retail;

-- Step 2: Create Branches Table
-- ============================================================================
-- Business Purpose: Store branch/store information
CREATE TABLE IF NOT EXISTS branches (
    branch_id VARCHAR(10) PRIMARY KEY,
    branch_name VARCHAR(100) NOT NULL,
    region VARCHAR(50) NOT NULL,
    city VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_region (region)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Insert branch data
INSERT INTO branches (branch_id, branch_name, region, city) VALUES
('S001', 'Store North', 'North', 'Delhi'),
('S002', 'Store South', 'South', 'Bangalore'),
('S003', 'Store East', 'East', 'Kolkata'),
('S004', 'Store West', 'West', 'Mumbai')
ON DUPLICATE KEY UPDATE branch_name=VALUES(branch_name);

-- Step 3: Create Products Table
-- ============================================================================
-- Business Purpose: Store product catalog with category and pricing
CREATE TABLE IF NOT EXISTS products (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    product_name VARCHAR(200) UNIQUE NOT NULL,
    category VARCHAR(50) NOT NULL,
    unit_price INT NOT NULL,
    profit_margin_percent INT DEFAULT 30,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_category (category),
    INDEX idx_price (unit_price)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Step 4: Create Customers Table
-- ============================================================================
-- Business Purpose: Store customer information and segmentation
CREATE TABLE IF NOT EXISTS customers (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_type VARCHAR(50) NOT NULL,
    customer_segment VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_type (customer_type),
    INDEX idx_segment (customer_segment)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Step 5: Create Transactions Table
-- ============================================================================
-- Business Purpose: Store all sales transactions and analysis
CREATE TABLE IF NOT EXISTS transactions (
    transaction_id INT AUTO_INCREMENT PRIMARY KEY,
    transaction_date DATE NOT NULL,
    branch_id VARCHAR(10) NOT NULL,
    product_name VARCHAR(200) NOT NULL,
    category VARCHAR(50) NOT NULL,
    customer_type VARCHAR(50) NOT NULL,
    customer_segment VARCHAR(50),
    quantity_sold INT NOT NULL,
    unit_price INT NOT NULL,
    total_sales INT NOT NULL,
    discount_percent DECIMAL(5, 2) DEFAULT 0.00,
    revenue INT NOT NULL,
    profit_margin_percent INT DEFAULT 30,
    estimated_profit DECIMAL(12, 2) NOT NULL,
    profit_margin DECIMAL(5, 2),
    sales_performance VARCHAR(20),
    
    -- Temporal columns
    year INT,
    month INT,
    day_of_week VARCHAR(10),
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Indexes for faster queries
    INDEX idx_date (transaction_date),
    INDEX idx_branch (branch_id),
    INDEX idx_category (category),
    INDEX idx_customer_type (customer_type),
    INDEX idx_performance (sales_performance),
    FOREIGN KEY (branch_id) REFERENCES branches(branch_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Step 6: Verify Tables
-- ============================================================================
-- Show table structure
SHOW TABLES;
SHOW CREATE TABLE transactions;

-- Summary
-- ============================================================================
-- Tables Created:
-- 1. branches         - 4 rows (S001-S004)
-- 2. products        - (to be populated from CSV)
-- 3. customers       - (to be populated from CSV)
-- 4. transactions    - (to be populated from CSV)
--
-- Next Steps:
-- 1. Run 02_import_data.sql to load transaction data
-- 2. Run 03_product_analysis.sql for product queries
-- 3. Run 04_customer_analysis.sql for customer queries
-- 4. Run 05_sales_analysis.sql for sales queries
-- ============================================================================
