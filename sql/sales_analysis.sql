-- ============================================================================
-- Smart Retail Analytics - Sales Analysis Queries
-- ============================================================================
-- File: sql/sales_analysis.sql
-- Purpose: Analyze revenue, profit, and sales trends by various dimensions
-- ============================================================================

USE smart_retail;

-- ============================================================================
-- QUERY 1: Revenue and Profit by Branch
-- Business Question: Which branch generates the highest revenue and profit?
-- ============================================================================
SELECT 
    'Revenue and Profit by Branch' as query_name,
    branch_id,
    COUNT(*) as transaction_count,
    SUM(revenue) as total_revenue,
    ROUND(AVG(revenue), 0) as avg_transaction_value,
    SUM(estimated_profit) as total_profit,
    ROUND(AVG(estimated_profit), 0) as avg_profit_per_transaction,
    ROUND(SUM(estimated_profit) / SUM(revenue) * 100, 2) as profit_margin_percent,
    ROUND(SUM(revenue) / (SELECT SUM(revenue) FROM transactions) * 100, 2) as revenue_share_percent
FROM transactions
GROUP BY branch_id
ORDER BY total_revenue DESC;

-- ============================================================================
-- QUERY 2: Monthly Revenue and Profit Trend
-- Business Question: How do sales and profits trend over time?
-- ============================================================================
SELECT 
    'Monthly Sales Trend' as query_name,
    year,
    month,
    COUNT(*) as transaction_count,
    SUM(revenue) as monthly_revenue,
    SUM(estimated_profit) as monthly_profit,
    ROUND(SUM(estimated_profit) / SUM(revenue) * 100, 2) as profit_margin_percent,
    ROUND(AVG(revenue), 0) as avg_transaction_value
FROM transactions
GROUP BY year, month
ORDER BY year DESC, month DESC;

-- ============================================================================
-- QUERY 3: Category Revenue vs Profit Analysis
-- Business Question: Which category is most profitable in absolute terms and by margin?
-- ============================================================================
SELECT 
    'Revenue and Profit by Category' as query_name,
    category,
    COUNT(*) as transaction_count,
    SUM(quantity_sold) as total_units_sold,
    SUM(revenue) as category_revenue,
    ROUND(AVG(revenue), 0) as avg_revenue_per_transaction,
    SUM(estimated_profit) as category_profit,
    ROUND(AVG(estimated_profit), 0) as avg_profit_per_transaction,
    ROUND(SUM(estimated_profit) / SUM(revenue) * 100, 2) as profit_margin_percent,
    ROUND(SUM(revenue) / (SELECT SUM(revenue) FROM transactions) * 100, 2) as revenue_contribution_percent
FROM transactions
GROUP BY category
ORDER BY category_revenue DESC;

-- ============================================================================
-- QUERY 4: High Sales but Low Profit Products
-- Business Question: Which products have high sales volume but low profit margins?
-- ============================================================================
SELECT 
    'High Sales Low Profit Products' as query_name,
    product_name,
    category,
    COUNT(*) as transaction_count,
    SUM(quantity_sold) as total_units_sold,
    ROUND(AVG(unit_price), 0) as avg_unit_price,
    SUM(revenue) as total_revenue,
    SUM(estimated_profit) as total_profit,
    ROUND(AVG(profit_margin), 2) as avg_margin_percent
FROM transactions
WHERE profit_margin < 30  -- Low profit threshold
GROUP BY product_name, category
HAVING transaction_count >= 2  -- Products with multiple transactions
ORDER BY total_revenue DESC
LIMIT 10;

-- ============================================================================
-- QUERY 5: Revenue and Profit by Customer Type
-- Business Question: Which customer segment (Online vs Offline) drives higher profitability?
-- ============================================================================
SELECT 
    'Sales Performance by Customer Type' as query_name,
    customer_type,
    COUNT(*) as transaction_count,
    SUM(revenue) as total_revenue,
    ROUND(AVG(revenue), 0) as avg_transaction_value,
    SUM(estimated_profit) as total_profit,
    ROUND(AVG(estimated_profit), 0) as avg_profit,
    ROUND(SUM(estimated_profit) / SUM(revenue) * 100, 2) as profit_margin_percent,
    ROUND(SUM(revenue) / (SELECT SUM(revenue) FROM transactions) * 100, 2) as revenue_share_percent
FROM transactions
GROUP BY customer_type
ORDER BY total_revenue DESC;

-- ============================================================================
-- QUERY 6: Discount Impact Analysis
-- Business Question: How does discounting affect volume and profitability?
-- ============================================================================
SELECT 
    'Discount Impact Analysis' as query_name,
    CASE 
        WHEN discount_percent = 0 THEN 'No Discount'
        WHEN discount_percent <= 5 THEN '0-5% Discount'
        WHEN discount_percent <= 10 THEN '5-10% Discount'
        ELSE '10%+ Discount'
    END as discount_tier,
    COUNT(*) as transaction_count,
    SUM(quantity_sold) as total_units,
    ROUND(AVG(quantity_sold), 1) as avg_units_per_transaction,
    SUM(revenue) as total_revenue,
    ROUND(AVG(revenue), 0) as avg_revenue,
    SUM(estimated_profit) as total_profit,
    ROUND(AVG(profit_margin), 2) as avg_profit_margin_percent
FROM transactions
GROUP BY discount_tier
ORDER BY discount_percent ASC;

-- ============================================================================
-- QUERY 7: Daily Sales Performance
-- Business Question: What is the daily revenue and profit trend?
-- ============================================================================
SELECT 
    'Daily Sales Performance' as query_name,
    transaction_date,
    day_of_week,
    COUNT(*) as daily_transactions,
    SUM(quantity_sold) as total_units,
    SUM(revenue) as daily_revenue,
    SUM(estimated_profit) as daily_profit,
    ROUND(SUM(estimated_profit) / SUM(revenue) * 100, 2) as daily_margin_percent,
    ROUND(AVG(revenue), 0) as avg_transaction_value
FROM transactions
GROUP BY transaction_date, day_of_week
ORDER BY transaction_date DESC;

-- ============================================================================
-- QUERY 8: Sales Performance Classification Analysis
-- Business Question: How are sales distributed across performance categories?
-- ============================================================================
SELECT 
    'Sales by Performance Classification' as query_name,
    sales_performance,
    COUNT(*) as transaction_count,
    ROUND(COUNT(*) / (SELECT COUNT(*) FROM transactions) * 100, 2) as percentage_of_total,
    SUM(revenue) as total_revenue,
    SUM(estimated_profit) as total_profit,
    ROUND(AVG(revenue), 0) as avg_revenue,
    ROUND(AVG(estimated_profit), 0) as avg_profit
FROM transactions
WHERE sales_performance IS NOT NULL
GROUP BY sales_performance
ORDER BY 
    CASE 
        WHEN sales_performance = 'Very High' THEN 1
        WHEN sales_performance = 'High' THEN 2
        WHEN sales_performance = 'Medium' THEN 3
        WHEN sales_performance = 'Low' THEN 4
    END;

-- ============================================================================
-- QUERY 9: Regional Performance Comparison
-- Business Question: How do different regions compare in revenue and profitability?
-- ============================================================================
SELECT 
    'Regional Performance' as query_name,
    branch_id,
    category,
    COUNT(*) as transaction_count,
    SUM(quantity_sold) as total_units,
    SUM(revenue) as regional_revenue,
    ROUND(AVG(revenue), 0) as avg_revenue,
    SUM(estimated_profit) as regional_profit,
    ROUND(SUM(estimated_profit) / SUM(revenue) * 100, 2) as margin_percent
FROM transactions
GROUP BY branch_id, category
ORDER BY branch_id, regional_revenue DESC;

-- ============================================================================
-- QUERY 10: Customer Segment Performance
-- Business Question: How do different customer segments perform?
-- ============================================================================
SELECT 
    'Customer Segment Performance' as query_name,
    customer_segment,
    COUNT(*) as transaction_count,
    SUM(quantity_sold) as total_units,
    SUM(revenue) as segment_revenue,
    ROUND(AVG(revenue), 0) as avg_transaction_value,
    SUM(estimated_profit) as segment_profit,
    ROUND(SUM(estimated_profit) / SUM(revenue) * 100, 2) as profit_margin_percent,
    ROUND(SUM(revenue) / (SELECT SUM(revenue) FROM transactions) * 100, 2) as revenue_share_percent
FROM transactions
WHERE customer_segment IS NOT NULL
GROUP BY customer_segment
ORDER BY segment_revenue DESC;

-- ============================================================================
-- SUMMARY STATISTICS
-- ============================================================================
SELECT 
    'Overall Business Summary' as metric,
    COUNT(*) as total_transactions,
    COUNT(DISTINCT branch_id) as num_branches,
    COUNT(DISTINCT category) as num_categories,
    COUNT(DISTINCT product_name) as num_products,
    COUNT(DISTINCT transaction_date) as num_trading_days,
    SUM(quantity_sold) as total_units_sold,
    SUM(revenue) as total_revenue,
    SUM(estimated_profit) as total_profit,
    ROUND(SUM(estimated_profit) / SUM(revenue) * 100, 2) as overall_profit_margin_percent,
    ROUND(AVG(revenue), 0) as avg_transaction_value
FROM transactions;

-- ============================================================================
-- END OF SALES ANALYSIS QUERIES
-- ============================================================================
