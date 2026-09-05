-- ============================================================================
-- Smart Retail Analytics - Product Analysis Queries
-- ============================================================================
-- File: sql/product_analysis.sql
-- Purpose: Analyze product performance, inventory, and profitability
-- ============================================================================

USE smart_retail;

-- ============================================================================
-- QUERY 1: Top 10 Products by Revenue
-- Business Question: Which products drive the most revenue?
-- ============================================================================
SELECT 
    'Top 10 Products by Revenue' as query_name,
    product_name,
    category,
    COUNT(*) as transaction_count,
    SUM(quantity_sold) as total_units_sold,
    ROUND(AVG(unit_price), 0) as avg_unit_price,
    SUM(revenue) as total_revenue,
    ROUND(SUM(revenue) / (SELECT SUM(revenue) FROM transactions) * 100, 2) as revenue_contribution_percent,
    SUM(estimated_profit) as total_profit,
    ROUND(AVG(profit_margin), 2) as avg_profit_margin_percent,
    ROUND(AVG(quantity_sold), 1) as avg_quantity_per_sale
FROM transactions
GROUP BY product_name, category
ORDER BY total_revenue DESC
LIMIT 10;

-- ============================================================================
-- QUERY 2: Top 10 Products by Profit
-- Business Question: Which products are most profitable?
-- ============================================================================
SELECT 
    'Top 10 Products by Profit' as query_name,
    product_name,
    category,
    COUNT(*) as transaction_count,
    SUM(quantity_sold) as total_units_sold,
    ROUND(AVG(unit_price), 0) as avg_unit_price,
    SUM(revenue) as total_revenue,
    SUM(estimated_profit) as total_profit,
    ROUND(SUM(estimated_profit) / (SELECT SUM(estimated_profit) FROM transactions) * 100, 2) as profit_contribution_percent,
    ROUND(AVG(profit_margin), 2) as avg_profit_margin_percent
FROM transactions
GROUP BY product_name, category
ORDER BY total_profit DESC
LIMIT 10;

-- ============================================================================
-- QUERY 3: Product Performance Ranking
-- Business Question: How do products rank across revenue, units, and margin?
-- ============================================================================
SELECT 
    'Comprehensive Product Performance' as query_name,
    product_name,
    category,
    COUNT(*) as sales_count,
    SUM(quantity_sold) as total_quantity,
    SUM(revenue) as total_revenue,
    SUM(estimated_profit) as total_profit,
    ROUND(AVG(revenue), 0) as avg_revenue_per_sale,
    ROUND(AVG(profit_margin), 2) as avg_profit_margin_percent,
    MIN(unit_price) as min_price,
    MAX(unit_price) as max_price,
    ROUND(AVG(unit_price), 0) as avg_price,
    ROUND(SUM(revenue) / SUM(quantity_sold), 0) as actual_avg_unit_price
FROM transactions
GROUP BY product_name, category
ORDER BY total_revenue DESC;

-- ============================================================================
-- QUERY 4: Product Category Profitability
-- Business Question: Which categories are most profitable per unit?
-- ============================================================================
SELECT 
    'Category-Level Profitability' as query_name,
    category,
    COUNT(*) as total_sales,
    SUM(quantity_sold) as total_units,
    COUNT(DISTINCT product_name) as num_products_in_category,
    SUM(revenue) as category_revenue,
    SUM(estimated_profit) as category_profit,
    ROUND(AVG(revenue), 0) as avg_revenue_per_transaction,
    ROUND(AVG(estimated_profit), 0) as avg_profit_per_transaction,
    ROUND(AVG(profit_margin), 2) as avg_profit_margin_percent,
    ROUND(SUM(revenue) / SUM(quantity_sold), 0) as revenue_per_unit,
    ROUND(SUM(estimated_profit) / SUM(quantity_sold), 0) as profit_per_unit
FROM transactions
GROUP BY category
ORDER BY category_profit DESC;

-- ============================================================================
-- QUERY 5: Product SKU Analysis - Low vs High Performers
-- Business Question: Which products should be promoted or discontinued?
-- ============================================================================
SELECT 
    'Product Performance Segmentation' as query_name,
    CASE 
        WHEN SUM(revenue) > (SELECT AVG(category_revenue) FROM (
            SELECT SUM(revenue) as category_revenue 
            FROM transactions 
            GROUP BY product_name
        ) t) THEN 'High Performer'
        ELSE 'Low Performer'
    END as performance_segment,
    product_name,
    category,
    COUNT(*) as sales_count,
    SUM(quantity_sold) as units_sold,
    SUM(revenue) as total_revenue,
    SUM(estimated_profit) as total_profit,
    ROUND(AVG(profit_margin), 2) as profit_margin_percent
FROM transactions
GROUP BY product_name, category
ORDER BY category, total_revenue DESC;

-- ============================================================================
-- QUERY 6: Product Velocity Analysis (Fast vs Slow Moving)
-- Business Question: How quickly do products sell?
-- ============================================================================
SELECT 
    'Product Velocity Analysis' as query_name,
    product_name,
    category,
    COUNT(DISTINCT transaction_date) as days_appeared,
    COUNT(*) as transaction_count,
    SUM(quantity_sold) as total_quantity,
    ROUND(SUM(quantity_sold) / COUNT(DISTINCT transaction_date), 2) as units_per_day,
    ROUND(COUNT(*) / COUNT(DISTINCT transaction_date), 2) as sales_per_day,
    CASE 
        WHEN (SUM(quantity_sold) / COUNT(DISTINCT transaction_date)) > 10 THEN 'Fast Moving'
        WHEN (SUM(quantity_sold) / COUNT(DISTINCT transaction_date)) > 5 THEN 'Medium Velocity'
        ELSE 'Slow Moving'
    END as velocity_classification
FROM transactions
GROUP BY product_name, category
ORDER BY units_per_day DESC;

-- ============================================================================
-- QUERY 7: Product-Branch Performance Matrix
-- Business Question: Which products sell best in which branches?
-- ============================================================================
SELECT 
    'Product by Branch Performance' as query_name,
    branch_id,
    product_name,
    category,
    COUNT(*) as sales_count,
    SUM(quantity_sold) as total_units,
    SUM(revenue) as branch_product_revenue,
    SUM(estimated_profit) as branch_product_profit,
    ROUND(AVG(profit_margin), 2) as profit_margin_percent
FROM transactions
GROUP BY branch_id, product_name, category
ORDER BY branch_id, branch_product_revenue DESC;

-- ============================================================================
-- QUERY 8: Price Elasticity Analysis
-- Business Question: How do products with different prices perform in volume?
-- ============================================================================
SELECT 
    'Price and Volume Analysis' as query_name,
    product_name,
    category,
    ROUND(AVG(unit_price), 0) as avg_price,
    CASE 
        WHEN AVG(unit_price) > 50000 THEN 'Premium (>₹50K)'
        WHEN AVG(unit_price) > 10000 THEN 'Mid-Range (₹10K-50K)'
        ELSE 'Budget (<₹10K)'
    END as price_segment,
    SUM(quantity_sold) as total_quantity,
    COUNT(*) as frequency,
    ROUND(AVG(quantity_sold), 1) as avg_quantity_per_sale,
    SUM(revenue) as total_revenue,
    ROUND(AVG(revenue), 0) as avg_revenue_per_transaction
FROM transactions
GROUP BY product_name, category
ORDER BY avg_price DESC;

-- ============================================================================
-- QUERY 9: Product Contribution to Profit
-- Business Question: Which 80% of products drive what % of profit? (Pareto Analysis)
-- ============================================================================
SELECT 
    'Pareto Analysis - Product Contribution' as query_name,
    product_name,
    category,
    SUM(estimated_profit) as product_profit,
    ROUND(SUM(estimated_profit) / (SELECT SUM(estimated_profit) FROM transactions) * 100, 2) as profit_contribution_percent,
    ROUND(SUM(estimated_profit) / (SELECT SUM(estimated_profit) FROM transactions) * 100, 2) +
        LAG(ROUND(SUM(estimated_profit) / (SELECT SUM(estimated_profit) FROM transactions) * 100, 2), 1, 0)
        OVER (ORDER BY SUM(estimated_profit) DESC) as cumulative_contribution_percent
FROM transactions
GROUP BY product_name, category
ORDER BY product_profit DESC;

-- ============================================================================
-- QUERY 10: Product Health Scorecard
-- Business Question: Overall health assessment of each product
-- ============================================================================
SELECT 
    'Product Health Scorecard' as query_name,
    product_name,
    category,
    COUNT(*) as sales_frequency,
    SUM(quantity_sold) as total_volume,
    ROUND(SUM(quantity_sold) / COUNT(*), 1) as avg_volume_per_sale,
    SUM(revenue) as total_revenue,
    ROUND(AVG(revenue), 0) as avg_transaction_value,
    SUM(estimated_profit) as total_profit,
    ROUND(AVG(profit_margin), 2) as margin_percent,
    CASE 
        WHEN COUNT(*) >= 3 AND AVG(profit_margin) >= 30 AND SUM(quantity_sold) >= 10 THEN 'Healthy'
        WHEN COUNT(*) >= 3 AND AVG(profit_margin) >= 30 THEN 'Good'
        WHEN COUNT(*) >= 2 AND AVG(profit_margin) >= 20 THEN 'Fair'
        ELSE 'Needs Review'
    END as health_status
FROM transactions
GROUP BY product_name, category
ORDER BY 
    CASE 
        WHEN COUNT(*) >= 3 AND AVG(profit_margin) >= 30 AND SUM(quantity_sold) >= 10 THEN 1
        WHEN COUNT(*) >= 3 AND AVG(profit_margin) >= 30 THEN 2
        WHEN COUNT(*) >= 2 AND AVG(profit_margin) >= 20 THEN 3
        ELSE 4
    END,
    total_revenue DESC;

-- ============================================================================
-- END OF PRODUCT ANALYSIS QUERIES
-- ============================================================================
