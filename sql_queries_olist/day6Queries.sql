-- Day 6: Advanced Date and Time Analysis

-- Goal: Solve complex problems involving date and time manipulation, advanced window functions, and multi-step analysis using CTEs.


-- Problem 1. Average Delivery Time by Weekday:
-- Calculate the average time (in days) it takes for an order to be delivered, broken down by the day of the week the order was placed.
-- Display the weekday (e.g., 'Monday'), and the average delivery time in days.
-- Order the results from Monday to Sunday.
SELECT
	TO_CHAR(order_purchase_timestamp, 'Day') AS weekday_of_purchase,
	AVG(EXTRACT(EPOCH FROM (order_delivered_customer_date - order_purchase_timestamp))) / 86400 AS avg_delivery_time_days
FROM
	olist_orders_dataset
WHERE
	order_delivered_customer_date IS NOT NULL
GROUP BY
	weekday_of_purchase, EXTRACT(DOW FROM order_purchase_timestamp)
ORDER BY
	EXTRACT(DOW FROM order_purchase_timestamp);

-- Problem 2. Late Order Rate by Seller:
-- For each seller, calculate the percentage of orders that were delivered late.
-- An order is considered late if order_delivered_customer_date is after order_estimated_delivery_date.
-- Only consider sellers with at least 50 orders.
-- Display the seller_id, total orders, and the late order percentage.
-- Order the results by the late order percentage in descending order.
WITH delivery_info AS (
	SELECT 
		oid.seller_id,
		od.order_id,
		CASE
		    WHEN (od.order_delivered_customer_date - od.order_estimated_delivery_date) > INTERVAL '0' THEN 1
		    ELSE 0
		END AS late_delivery
	FROM
		olist_order_items_dataset AS oid
	INNER JOIN
		olist_orders_dataset AS od ON oid.order_id=od.order_id
)
SELECT
	seller_id,
	count(order_id) AS total_orders,
	SUM(late_delivery)*1.0/COUNT(order_id) AS late_order_percentage
FROM
	delivery_info
GROUP BY
	seller_id
HAVING count(order_id)>=50
ORDER BY late_order_percentage DESC;


-- Problem 3. Customer Growth by Region:
-- Find the number of new customers acquired each month, broken down by customer_state.
-- A new customer is defined by their first-ever order.
-- Display the year-month, customer_state, and the count of new customers.
-- Order the results chronologically.
WITH customer_first_order AS (
    SELECT
        customer_unique_id,
		customer_state,
        order_purchase_timestamp,
        ROW_NUMBER() OVER(PARTITION BY customer_unique_id ORDER BY order_purchase_timestamp) AS rn
    FROM
        olist_orders_dataset AS o
    INNER JOIN
        olist_customers_dataset AS c ON o.customer_id = c.customer_id
)
SELECT
    TO_CHAR(order_purchase_timestamp, 'YYYY-MM') AS year_month,
	customer_state,
    COUNT(customer_unique_id) AS new_customers_count
FROM
    customer_first_order
WHERE
    rn = 1
GROUP BY
    year_month,
	customer_state
ORDER BY
    year_month,
	customer_state;

-- Problem 4. Time Between Order and Review:
-- Calculate the average time (in hours) between when an order was placed and when the first review was created for that order.
-- Display the average time in hours.
WITH first_review_per_order AS (
    SELECT
        ord.order_id,
        MIN(ord.review_creation_date) AS first_review_date
    FROM
        olist_order_reviews_dataset AS ord
    GROUP BY
        ord.order_id
)
SELECT
    AVG(EXTRACT(EPOCH FROM (frpo.first_review_date - o.order_purchase_timestamp))) / 3600 AS avg_review_time_hrs
FROM
    first_review_per_order AS frpo
INNER JOIN
    olist_orders_dataset AS o
    ON frpo.order_id = o.order_id;
	

-- Problem 5. Highest Rated Product of the Month:
-- For each month, identify the product_id that received the highest average review score.
-- If there's a tie, all products with the highest score should be included.
-- Display the year-month, product_id, and the average review score.
-- Order the results chronologically.
WITH monthly_score_ratings AS (
    SELECT
        TO_CHAR(od.order_purchase_timestamp, 'YYYY-MM') AS year_month,
        oid.product_id,
        AVG(ord.review_score) AS average_score
    FROM
        olist_orders_dataset AS od
    INNER JOIN
        olist_order_items_dataset AS oid ON od.order_id = oid.order_id
    INNER JOIN
        olist_order_reviews_dataset AS ord ON oid.order_id = ord.order_id
    GROUP BY
        year_month,
        oid.product_id
),
ranked_products AS (
    SELECT
        year_month,
        product_id,
        average_score,
        DENSE_RANK() OVER(PARTITION BY year_month ORDER BY average_score DESC) AS ranking
    FROM
        monthly_score_ratings
)
SELECT
    year_month,
    product_id,
    average_score
FROM
    ranked_products
WHERE
    ranking = 1
ORDER BY
    year_month;

-- Problem 6. Average Delivery Time by Shipping Carrier:
-- Calculate the average delivery time (in days) for each unique shipping carrier (seller_id or carrier_id).
-- Display the carrier_id and the average delivery time.
-- Order the results by average delivery time.
WITH delivery_times AS (
	SELECT
		oid.seller_id,
		AVG(EXTRACT(EPOCH FROM (od.order_delivered_customer_date - od.order_purchase_timestamp))) / 86400 AS avg_delivery_time_days
	FROM
		olist_order_items_dataset AS oid
	INNER JOIN
		olist_orders_dataset AS od ON oid.order_id=od.order_id
	GROUP BY oid.seller_id
	ORDER BY avg_delivery_time_days DESC
)
SELECT
	seller_id,
	avg_delivery_time_days
FROM delivery_times
WHERE avg_delivery_time_days IS NOT NULL;
	


-- Problem 7. Customer LTV (Lifetime Value) by Acquisition Month:
-- Calculate the total revenue generated by customers acquired in each month.
-- Display the acquisition_month (YYYY-MM) and the total revenue from that cohort of customers.
-- Use a CTE to first identify each customer's acquisition month.
WITH customer_cohort AS (
    SELECT
        c.customer_unique_id,
        TO_CHAR(MIN(o.order_purchase_timestamp), 'YYYY-MM') AS acquisition_month
    FROM
        olist_customers_dataset AS c
    INNER JOIN
        olist_orders_dataset AS o ON c.customer_id = o.customer_id
    GROUP BY
        c.customer_unique_id
)
SELECT
    cc.acquisition_month,
    SUM(oi.price + oi.freight_value) AS total_revenue
FROM
    customer_cohort AS cc
INNER JOIN
    olist_customers_dataset AS c ON cc.customer_unique_id = c.customer_unique_id
INNER JOIN
    olist_orders_dataset AS o ON c.customer_id = o.customer_id
INNER JOIN
    olist_order_items_dataset AS oi ON o.order_id = oi.order_id
GROUP BY
    cc.acquisition_month
ORDER BY
    cc.acquisition_month;
	
