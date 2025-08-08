-- Day 4: Advanced Synthesis

-- Goal: Use a combination of joins, subqueries, CTEs, and window functions to solve complex, multi-step business problems.


-- Problem 1. Orders by Payment Type Over Time:
-- Calculate the number of orders for each payment_type on a monthly basis.
-- Display the year-month (YYYY-MM format), payment_type, and the count of orders for that combination.
-- Order the results chronologically.
SELECT
	TO_CHAR(od.order_purchase_timestamp, 'YYYY-MM') AS year_month,
	opd.payment_type,
	COUNT(DISTINCT opd.order_id) AS order_count
FROM olist_order_payments_dataset AS opd
INNER JOIN
	olist_orders_dataset AS od ON opd.order_id=od.order_id
GROUP BY year_month, payment_type
ORDER BY year_month, payment_type;

-- Problem 2. Products with the Highest Cancellation Rate:
-- Find the top 5 product_id's with the highest order cancellation rate.
-- The cancellation rate is defined as (number of cancelled orders / total number of orders for that product).
-- Consider products with at least 50 total orders to ensure the rate is meaningful.
-- Display the product_id, total orders, total cancelled orders, and the cancellation rate percentage.
WITH product_order_summary AS (
    SELECT
        oi.product_id,
        COUNT(DISTINCT o.order_id) AS total_orders,
        SUM(CASE WHEN o.order_status = 'canceled' THEN 1 ELSE 0 END) AS canceled_orders
    FROM
        olist_order_items_dataset AS oi
    INNER JOIN
        olist_orders_dataset AS o ON oi.order_id = o.order_id
    GROUP BY
        oi.product_id
    HAVING
        COUNT(DISTINCT o.order_id) >= 50
)
SELECT
    product_id,
    total_orders,
    canceled_orders,
    (CAST(canceled_orders AS FLOAT) / total_orders) AS cancellation_rate
FROM
    product_order_summary
ORDER BY
    cancellation_rate DESC
LIMIT 5;


-- Problem 3. Average Review Score for On-Time Deliveries:
-- For each product_category_name_english, find the average review score, but only for orders that were delivered on or before their estimated delivery date.
-- Display the product_category_name_english and the average review score.
-- Order by the average score in descending order.
WITH delivered_order_score AS(
	SELECT
		pcnt.product_category_name_english,
		od.order_status,
		ord.review_score
	FROM product_category_name_translation AS pcnt
	INNER JOIN
		olist_products_dataset AS pd ON pcnt.product_category_name=pd.product_category_name
	INNER JOIN
		olist_order_items_dataset AS oid ON pd.product_id=oid.product_id
	INNER JOIN olist_orders_dataset AS od ON oid.order_id=od.order_id
	INNER JOIN olist_order_reviews_dataset AS ord ON od.order_id=ord.order_id
	WHERE od.order_delivered_customer_date <= od.order_estimated_delivery_date
)
SELECT
	product_category_name_english,
	AVG(review_score) AS avg_score
FROM delivered_order_score
GROUP BY product_category_name_english
ORDER BY avg_score DESC;
	

-- Problem 4. Customers who Re-purchased from a Seller:
-- Identify customer_unique_id's who have placed more than one order with the same seller.
-- List the customer_unique_id, seller_id, and the total number of orders placed between them.
-- Only include results where the total number of orders is greater than 1.
SELECT
    c.customer_unique_id,
    oi.seller_id,
    COUNT(DISTINCT o.order_id) AS total_orders
FROM
    olist_customers_dataset AS c
INNER JOIN
    olist_orders_dataset AS o ON c.customer_id = o.customer_id
INNER JOIN
    olist_order_items_dataset AS oi ON o.order_id = oi.order_id
GROUP BY
    c.customer_unique_id,
    oi.seller_id
HAVING
    COUNT(DISTINCT o.order_id) > 1
ORDER BY
    total_orders DESC;

	
-- Problem 5. Sellers with Wide Product Portfolios:
-- Find seller_id's who have sold products from more than 5 different product categories.
-- Display the seller_id and the count of distinct categories they have sold in.
-- Order the results by the count of categories in descending order.
SELECT
	oid.seller_id,
	COUNT(DISTINCT pd.product_category_name) AS distinct_category_count
FROM olist_order_items_dataset AS oid
INNER JOIN
	olist_products_dataset AS pd ON oid.product_id=pd.product_id
GROUP BY oid.seller_id
HAVING COUNT(DISTINCT pd.product_category_name)>5
ORDER BY distinct_category_count DESC;

-- Problem 6. Average Delivery Time vs. Estimated Time per State:
-- Calculate the average difference in days between the actual delivery date and the estimated delivery date for each customer_state.
-- The difference should be calculated as (order_delivered_customer_date - order_estimated_delivery_date). A negative number means an early delivery.
-- Display the customer_state and the average difference in days, rounded to 2 decimal places.
SELECT cd.customer_state,
	ROUND(AVG(EXTRACT(EPOCH FROM (od.order_delivered_customer_date - od.order_estimated_delivery_date)) / 86400), 2) AS average_days_between
FROM olist_customers_dataset AS cd
INNER JOIN olist_orders_dataset AS od ON cd.customer_id=od.customer_id
WHERE
    od.order_delivered_customer_date IS NOT NULL
GROUP BY cd.customer_state
ORDER BY
    average_days_between DESC;

-- Problem 7. Orders with High Product Price vs. Freight:
-- Find the order_id's where the total price of all items from a single seller is more than twice the total freight value for that entire order.
-- List the order_id and the seller_id.
-- You will need to calculate the total price per seller per order and the total freight value per order, then compare them.
WITH seller_item_price AS (
    SELECT
        order_id,
        seller_id,
        SUM(price) AS total_price_per_seller
    FROM
        olist_order_items_dataset
    GROUP BY
        order_id,
        seller_id
)
SELECT
    sip.order_id,
    sip.seller_id
FROM
    seller_item_price AS sip
INNER JOIN
    olist_order_items_dataset AS oid ON sip.order_id = oid.order_id
GROUP BY
    sip.order_id,
    sip.seller_id,
    sip.total_price_per_seller
HAVING
    sip.total_price_per_seller > SUM(oid.freight_value) * 2
ORDER BY
    sip.total_price_per_seller DESC;
