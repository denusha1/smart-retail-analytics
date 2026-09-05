-- ============================================================================
-- Smart Retail Analytics - Customer Analysis Queries
-- ============================================================================
-- File: sql/customer_analysis.sql
-- Purpose: Analyze customer behavior, segmentation, and lifetime value
-- ============================================================================

USE smart_retail;

-- ============================================================================
-- QUERY 1: Top 20 Customers by Total Spend
-- Business Question: Who are the highest-value customers?
-- ============================================================================
SELECT 
    'Top 20 Customers by Spend' as query_name,
    @row_number:=@row_number+1 as customer_rank,
    customer_type,
    customer_segment,
    COUNT(*) as purchase_frequency,
    SUM(quantity_sold) as total_units_purchased,
    SUM(revenue) as total_customer_spend,
    SUM(estimated_profit) as customer_profit_contribution,
    ROUND(AVG(revenue), 0) as avg_purchase_value,
    ROUND(MAX(revenue), 0) as highest_purchase,
    ROUND(MIN(revenue), 0) as lowest_purchase,
    COUNT(DISTINCT transaction_date) as num_purchase_days,
    COUNT(DISTINCT category) as num_categories_purchased
FROM transactions, (SELECT @row_number:=0) as t
GROUP BY customer_type, customer_segment
ORDER BY total_customer_spend DESC
LIMIT 20;

-- ============================================================================
-- QUERY 2: Customer Segmentation Analysis
-- Business Question: How are customers distributed across segments?
-- ============================================================================
SELECT 
    'Customer Segmentation Overview' as query_name,
    customer_segment,
    COUNT(DISTINCT customer_type) as customer_types,
    COUNT(*) as total_transactions,
    COUNT(DISTINCT transaction_date) as purchase_days,
    SUM(quantity_sold) as total_units,
    SUM(revenue) as segment_revenue,
    SUM(estimated_profit) as segment_profit,
    ROUND(SUM(revenue) / (SELECT SUM(revenue) FROM transactions) * 100, 2) as revenue_share_percent,
    ROUND(AVG(revenue), 0) as avg_transaction_value,
    ROUND(AVG(estimated_profit), 0) as avg_profit_per_transaction,
    ROUND(SUM(estimated_profit) / SUM(revenue) * 100, 2) as profit_margin_percent
FROM transactions
WHERE customer_segment IS NOT NULL
GROUP BY customer_segment
ORDER BY segment_revenue DESC;

-- ============================================================================
-- QUERY 3: Customer Type (Online vs Offline) Behavior
-- Business Question: How do different customer channels differ in behavior?
-- ============================================================================
SELECT 
    'Customer Type Behavior Analysis' as query_name,
    customer_type,
    COUNT(*) as total_transactions,
    COUNT(DISTINCT customer_segment) as segment_count,
    SUM(quantity_sold) as total_units,
    SUM(revenue) as type_revenue,
    ROUND(AVG(revenue), 0) as avg_transaction_value,
    ROUND(MIN(revenue), 0) as min_transaction,
    ROUND(MAX(revenue), 0) as max_transaction,
    ROUND(STDDEV(revenue), 0) as revenue_std_deviation,
    SUM(estimated_profit) as type_profit,
    ROUND(SUM(estimated_profit) / SUM(revenue) * 100, 2) as profit_margin_percent,
    COUNT(DISTINCT category) as categories_purchased,
    COUNT(DISTINCT transaction_date) as active_days
FROM transactions
GROUP BY customer_type
ORDER BY type_revenue DESC;

-- ============================================================================
-- QUERY 4: Customer Purchase Patterns by Category
-- Business Question: What products do different customer segments prefer?
-- ============================================================================
SELECT 
    'Customer Segment Category Preferences' as query_name,
    customer_segment,
    category,
    COUNT(*) as purchase_count,
    SUM(quantity_sold) as units_purchased,
    SUM(revenue) as category_revenue,
    ROUND(SUM(revenue) / 
        (SELECT SUM(revenue) FROM transactions t2 
         WHERE t2.customer_segment = transactions.customer_segment) * 100, 2) as pct_of_segment_revenue,
    ROUND(AVG(profit_margin), 2) as avg_margin_percent,
    ROUND(AVG(revenue), 0) as avg_purchase_value
FROM transactions
WHERE customer_segment IS NOT NULL
GROUP BY customer_segment, category
ORDER BY customer_segment, category_revenue DESC;

-- ============================================================================
-- QUERY 5: High-Value vs Low-Value Customer Analysis
-- Business Question: How do high-value and low-value customers differ?
-- ============================================================================
SELECT 
    'High vs Low Value Customer Segments' as query_name,
    CASE 
        WHEN total_spend > (SELECT PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY total_spend) 
                           FROM (SELECT SUM(revenue) as total_spend FROM transactions 
                                 GROUP BY customer_segment) t1)
        THEN 'High Value'
        WHEN total_spend > (SELECT PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY total_spend) 
                           FROM (SELECT SUM(revenue) as total_spend FROM transactions 
                                 GROUP BY customer_segment) t1)
        THEN 'Medium Value'
        ELSE 'Low Value'
    END as customer_value_tier,
    customer_segment,
    COUNT(*) as transaction_count,
    SUM(revenue) as total_revenue,
    ROUND(AVG(revenue), 0) as avg_purchase_value,
    SUM(estimated_profit) as total_profit,
    ROUND(AVG(profit_margin), 2) as avg_margin_percent,
    COUNT(DISTINCT category) as num_categories_purchased
FROM transactions
WHERE customer_segment IS NOT NULL
GROUP BY customer_value_tier, customer_segment
ORDER BY customer_value_tier, total_revenue DESC;

-- ============================================================================
-- QUERY 6: Customer Loyalty Metrics
-- Business Question: How frequently do customers purchase and how much do they spend?
-- ============================================================================
SELECT 
    'Customer Loyalty & Frequency Analysis' as query_name,
    customer_segment,
    COUNT(*) as purchase_frequency,
    CASE 
        WHEN COUNT(*) >= 4 THEN 'Very Loyal (4+ purchases)'
        WHEN COUNT(*) >= 3 THEN 'Loyal (3 purchases)'
        WHEN COUNT(*) >= 2 THEN 'Returning (2 purchases)'
        ELSE 'One-Time (1 purchase)'
    END as loyalty_category,
    SUM(revenue) as lifetime_revenue,
    ROUND(AVG(revenue), 0) as avg_purchase_value,
    SUM(estimated_profit) as lifetime_profit,
    COUNT(DISTINCT transaction_date) as days_active,
    COUNT(DISTINCT product_name) as products_purchased,
    COUNT(DISTINCT category) as categories_purchased
FROM transactions
WHERE customer_segment IS NOT NULL
GROUP BY customer_segment
ORDER BY purchase_frequency DESC, lifetime_revenue DESC;

-- ============================================================================
-- QUERY 7: Customer Acquisition Cost & Lifetime Value (LTV)
-- Business Question: What is the profitability per customer segment?
-- ============================================================================
SELECT 
    'Customer Lifetime Value Analysis' as query_name,
    customer_segment,
    COUNT(*) as num_purchases,
    SUM(revenue) as total_revenue,
    SUM(estimated_profit) as total_profit,
    ROUND(SUM(revenue) / COUNT(*), 0) as revenue_per_purchase,
    ROUND(SUM(estimated_profit) / COUNT(*), 0) as profit_per_purchase,
    ROUND(SUM(estimated_profit) / SUM(revenue) * 100, 2) as profit_margin_percent,
    ROUND(SUM(profit_margin) / COUNT(*), 2) as avg_margin_percent,
    COUNT(DISTINCT transaction_date) as active_days,
    ROUND(SUM(estimated_profit) / COUNT(DISTINCT transaction_date), 0) as daily_profit_contribution
FROM transactions
WHERE customer_segment IS NOT NULL
GROUP BY customer_segment
ORDER BY total_profit DESC;

-- ============================================================================
-- QUERY 8: Customer Seasonality & Purchase Timing
-- Business Question: When do customers purchase? Any patterns?
-- ============================================================================
SELECT 
    'Customer Purchase Timing Patterns' as query_name,
    customer_segment,
    day_of_week,
    COUNT(*) as purchase_count,
    SUM(quantity_sold) as units_purchased,
    SUM(revenue) as daily_revenue,
    ROUND(AVG(revenue), 0) as avg_transaction_value,
    SUM(estimated_profit) as daily_profit
FROM transactions
WHERE customer_segment IS NOT NULL
GROUP BY customer_segment, day_of_week
ORDER BY customer_segment, 
    CASE day_of_week
        WHEN 'Monday' THEN 1
        WHEN 'Tuesday' THEN 2
        WHEN 'Wednesday' THEN 3
        WHEN 'Thursday' THEN 4
        WHEN 'Friday' THEN 5
        WHEN 'Saturday' THEN 6
        WHEN 'Sunday' THEN 7
    END;

-- ============================================================================
-- QUERY 9: Customer Product Affinity Analysis
-- Business Question: Which products are most popular with each customer segment?
-- ============================================================================
SELECT 
    'Customer Segment Product Affinity' as query_name,
    customer_segment,
    product_name,
    category,
    COUNT(*) as purchase_count,
    SUM(quantity_sold) as total_units,
    SUM(revenue) as product_revenue,
    ROUND(SUM(revenue) / 
        (SELECT SUM(revenue) FROM transactions t2 
         WHERE t2.customer_segment = transactions.customer_segment) * 100, 2) as pct_of_segment_revenue,
    SUM(estimated_profit) as product_profit,
    ROUND(AVG(profit_margin), 2) as profit_margin_percent
FROM transactions
WHERE customer_segment IS NOT NULL
GROUP BY customer_segment, product_name, category
ORDER BY customer_segment, product_revenue DESC;

-- ============================================================================
-- QUERY 10: Customer Churn Risk & Engagement
-- Business Question: Which customers are at risk of becoming inactive?
-- ============================================================================
SELECT 
    'Customer Engagement & Retention' as query_name,
    customer_segment,
    CASE 
        WHEN MAX(transaction_date) = CURDATE() THEN 'Active Today'
        WHEN MAX(transaction_date) >= DATE_SUB(CURDATE(), INTERVAL 3 DAY) THEN 'Recently Active'
        WHEN MAX(transaction_date) >= DATE_SUB(CURDATE(), INTERVAL 7 DAY) THEN 'Moderately Active'
        ELSE 'At Risk / Inactive'
    END as engagement_status,
    COUNT(*) as total_purchases,
    ROUND(AVG(revenue), 0) as avg_purchase_value,
    SUM(revenue) as total_lifetime_value,
    SUM(estimated_profit) as total_profit_contribution,
    DATEDIFF(CURDATE(), MAX(transaction_date)) as days_since_last_purchase,
    DATEDIFF(MAX(transaction_date), MIN(transaction_date)) as customer_tenure_days
FROM transactions
WHERE customer_segment IS NOT NULL
GROUP BY customer_segment, engagement_status
ORDER BY customer_segment, days_since_last_purchase ASC;

-- ============================================================================
-- SUMMARY: Customer Distribution
-- ============================================================================
SELECT 
    'Customer Base Summary' as metric,
    COUNT(DISTINCT customer_segment) as total_segments,
    COUNT(*) as total_transactions,
    COUNT(DISTINCT customer_type) as customer_types,
    SUM(revenue) as total_customer_revenue,
    SUM(estimated_profit) as total_profit,
    ROUND(AVG(revenue), 0) as avg_transaction_value,
    ROUND(SUM(estimated_profit) / SUM(revenue) * 100, 2) as overall_margin_percent,
    COUNT(DISTINCT transaction_date) as trading_days
FROM transactions;

-- ============================================================================
-- END OF CUSTOMER ANALYSIS QUERIES
-- ============================================================================
