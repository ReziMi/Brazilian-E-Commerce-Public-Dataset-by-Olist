-- Day 2: Intermediate - Complex Joins, Subqueries, & Date Functions

-- Goal: Master more intricate data retrieval patterns by combining information from several tables,
--       using subqueries for specific lookups, and extracting insights from date/time data.

-- Key Concepts for Today: LEFT JOIN, RIGHT JOIN, multiple JOINs, GROUP BY with multiple columns,
--                         DATE_TRUNC, EXTRACT, TO_CHAR for date manipulation.


-- Problem 1. Orders Without Reviews:
-- Find all order_id's that do not have an associated review in the olist_order_reviews_dataset.
-- Count the total number of such orders.
SELECT
    COUNT(o.order_id) AS orders_without_reviews_count
FROM
    olist_orders_dataset AS o
LEFT JOIN
    olist_order_reviews_dataset AS r ON o.order_id = r.order_id
WHERE
    r.review_id IS NULL;


-- Problem 2. Product Category Sales (Translated):
-- Calculate the total revenue (price + freight_value) for each product category,
-- using the *translated English category names* from product_category_name_translation.
-- List the top 5 product categories by total revenue, in descending order.
SELECT
    pct.product_category_name_english,
    SUM(oi.price + oi.freight_value) AS total_revenue
FROM
    product_category_name_translation AS pct
INNER JOIN
    olist_products_dataset AS p ON p.product_category_name = pct.product_category_name
INNER JOIN
    olist_order_items_dataset AS oi ON oi.product_id = p.product_id 
GROUP BY
    pct.product_category_name_english
ORDER BY
    total_revenue DESC
LIMIT 5;


-- Problem 3. Customer Order Frequency:
-- For each customer_unique_id, calculate the total number of orders they have placed.
-- List the top 10 customer_unique_id's with the highest order count, along with their count.
SELECT
    c.customer_unique_id,
    COUNT(o.order_id) AS total_orders_by_id
FROM
    olist_customers_dataset AS c
INNER JOIN
    olist_orders_dataset AS o ON c.customer_id = o.customer_id
GROUP BY
    c.customer_unique_id
ORDER BY
    total_orders_by_id DESC
LIMIT 10;
	
-- Problem 4. Average Product Review Score:
-- Calculate the average review_score for each product_id.
-- List the top 5 product_id's with the highest average review score
-- (assume a product needs at least 5 reviews to be considered for this list, to avoid skewed averages from very few reviews).
SELECT pd.product_id,
	AVG(ord.review_score) AS average_review_per_id
FROM olist_products_dataset AS pd
INNER JOIN
	olist_order_items_dataset AS oid ON oid.product_id=pd.product_id
INNER JOIN
	olist_order_reviews_dataset AS ord ON ord.order_id=oid.order_id
GROUP BY pd.product_id
HAVING
    COUNT(ord.review_score) >= 5
ORDER BY average_review_per_id DESC
LIMIT 5;

-- Problem 5. Monthly Sales Trend:
-- Calculate the total revenue (price + freight_value) generated each month.
-- Display the year and month (e.g., 'YYYY-MM') and the total revenue for that month, ordered chronologically.
SELECT
    TO_CHAR(od.order_purchase_timestamp, 'YYYY-MM') AS year_month, -- Format as YYYY-MM
    SUM(oi.price + oi.freight_value) AS total_revenue_per_month
FROM
    olist_order_items_dataset AS oi
INNER JOIN 
    olist_orders_dataset AS od ON od.order_id = oi.order_id
GROUP BY
    year_month
ORDER BY
    year_month; 

-- Problem 6. Sellers with Diverse Categories:
-- Identify the seller_id's who have sold products from the most distinct (unique) product categories.
-- List the top 3 sellers by the count of distinct product categories they've sold from, in descending order.
SELECT oid.seller_id,
	COUNT(DISTINCT pd.product_category_name) AS number_of_distinct_categories
FROM olist_order_items_dataset AS oid
INNER JOIN
	olist_products_dataset AS pd ON pd.product_id=oid.product_id
GROUP BY oid.seller_id
ORDER BY number_of_distinct_categories DESC
LIMIT 3;

-- Problem 7. Customers with Varied Payment Methods:
-- Find the customer_unique_id's who have used more than one distinct payment_type across all their orders.
-- List these unique customer IDs.
SELECT
    c.customer_unique_id,
    COUNT(DISTINCT opd.payment_type) AS number_of_distinct_payment_types
FROM
    olist_customers_dataset AS c 
INNER JOIN
    olist_orders_dataset AS o ON c.customer_id = o.customer_id 
INNER JOIN
    olist_order_payments_dataset AS opd ON o.order_id = opd.order_id 
GROUP BY
    c.customer_unique_id
HAVING
    COUNT(DISTINCT opd.payment_type) > 1;
