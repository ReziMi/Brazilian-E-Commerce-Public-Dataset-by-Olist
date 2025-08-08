-- Day 5: Key Business Questions

-- Goal: Use a combination of skills to answer complex, project-based business questions.


-- Problem 1. Monthly Sales Performance by State:
-- Calculate the total revenue and total number of orders for each customer_state on a monthly basis.
-- KPIs to report: customer_state, year-month (YYYY-MM format), total_revenue, and order_volume.
-- Order the results chronologically.
SELECT 
	cd.customer_state,
	TO_CHAR(od.order_purchase_timestamp, 'YYYY-MM') AS year_month,
	SUM(oid.price+oid.freight_value) AS total_revenue,
	COUNT(DISTINCT oid.order_id) AS order_volume
FROM olist_customers_dataset AS cd
INNER JOIN
	olist_orders_dataset AS od ON cd.customer_id=od.customer_id
INNER JOIN
	olist_order_items_dataset AS oid ON od.order_id=oid.order_id
GROUP BY cd.customer_state, year_month
ORDER BY year_month, cd.customer_state;

-- Problem 2. Customer Acquisition Cohort Analysis:
-- Identify the total number of new customers acquired each month.
-- A new customer is defined by their first-ever purchase.
-- Metrics to report: year-month of acquisition and the count of new customers.
WITH customer_first_order AS (
    SELECT
        customer_unique_id,
        order_purchase_timestamp,
        ROW_NUMBER() OVER(PARTITION BY customer_unique_id ORDER BY order_purchase_timestamp) AS rn
    FROM
        olist_orders_dataset AS o
    INNER JOIN
        olist_customers_dataset AS c ON o.customer_id = c.customer_id
)
SELECT
    TO_CHAR(order_purchase_timestamp, 'YYYY-MM') AS year_month,
    COUNT(customer_unique_id) AS new_customers_count
FROM
    customer_first_order
WHERE
    rn = 1
GROUP BY
    year_month
ORDER BY
    year_month;

-- Problem 3. Seller Performance by Customer Satisfaction:
-- For each product_category_name_english, rank the sellers based on their average review score.
-- Only consider sellers with at least 10 reviews in that category.
-- Metrics to report: product_category_name_english, seller_id, average_review_score, and the rank within their category.
WITH seller_category_metrics AS (
    SELECT
        pcnt.product_category_name_english,
        oid.seller_id,
        AVG(ord.review_score) AS average_review_score,
        COUNT(ord.review_score) AS review_count
    FROM
        olist_products_dataset AS pd
    INNER JOIN
        product_category_name_translation AS pcnt
        ON pd.product_category_name = pcnt.product_category_name
    INNER JOIN
        olist_order_items_dataset AS oid
        ON pd.product_id = oid.product_id
    INNER JOIN
        olist_order_reviews_dataset AS ord
        ON oid.order_id = ord.order_id
    GROUP BY
        pcnt.product_category_name_english,
        oid.seller_id
)
SELECT
    product_category_name_english,
    seller_id,
    average_review_score,
    DENSE_RANK() OVER(PARTITION BY product_category_name_english ORDER BY average_review_score DESC) AS seller_rank
FROM
    seller_category_metrics
WHERE
    review_count >= 10
ORDER BY
    product_category_name_english,
    seller_rank;


-- Problem 4. Order Fulfillment Process Monitoring:
-- Calculate the number of orders in each order_status per month.
-- Metrics to report: order_status, year-month, and order_count.
SELECT
	order_status,
	TO_CHAR(order_purchase_timestamp, 'YYYY-MM') AS year_month,
	count(order_id)
FROM olist_orders_dataset
GROUP BY 1, 2
ORDER BY 1, 2;

-- Problem 5. AOV (Average Order Value) Trend Analysis:
-- Calculate the Average Order Value (AOV) for each customer_state on a monthly basis.
-- AOV is defined as the total revenue (price + freight) per order.
-- Metrics to report: customer_state, year-month, total_revenue, total_orders, and the calculated AOV.
SELECT
	cd.customer_state,
	TO_CHAR(od.order_purchase_timestamp, 'YYYY-MM') AS year_month,
	SUM(oid.price+oid.freight_value) AS total_revenue,
	COUNT(DISTINCT oid.order_id) AS total_orders,
	SUM(oid.price+oid.freight_value)/COUNT(DISTINCT oid.order_id) AS AOV
FROM olist_customers_dataset AS cd
INNER JOIN 
	olist_orders_dataset AS od ON cd.customer_id=od.customer_id
INNER JOIN
	olist_order_items_dataset AS oid ON od.order_id=oid.order_id
GROUP BY
	cd.customer_state,
	year_month
ORDER BY
	cd.customer_state,
	year_month;

-- Problem 6. Customer Payment Diversity Analysis:
-- Find the customer_unique_id's who have used more than one distinct payment_type across all their orders.
-- Metrics to report: customer_unique_id and the count of distinct payment types used.
-- Only show customers who have used more than one type.
SELECT
	cd.customer_unique_id,
	count(DISTINCT opd.payment_type) AS payment_types_count
FROM olist_customers_dataset AS cd
INNER JOIN
	olist_orders_dataset AS od ON cd.customer_id=od.customer_id
INNER JOIN
	olist_order_payments_dataset AS opd ON od.order_id=opd.order_id
GROUP BY cd.customer_unique_id
HAVING
	COUNT(DISTINCT opd.payment_type) > 1
ORDER BY payment_types_count DESC;

-- Problem 7. Best-Selling, High-Quality Products:
-- Find the top 5 most sold products (product_id) that also have an average review score of 4 or higher.
-- Metrics to report: product_id, total_items_sold, and average_review_score.
SELECT 
	oid.product_id,
	COUNT(oid.order_id) AS total_items_sold,
	AVG(ord.review_score) AS average_review_score
FROM olist_order_items_dataset AS oid
INNER JOIN
	olist_order_reviews_dataset AS ord ON oid.order_id=ord.order_id
GROUP BY 1
HAVING AVG(ord.review_score)>=4
ORDER BY average_review_score DESC
LIMIT 5;
	
