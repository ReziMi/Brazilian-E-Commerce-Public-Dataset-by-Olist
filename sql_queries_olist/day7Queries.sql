-- Problem 1. Customer Retention Rate:
-- Calculate the percentage of customers who placed a second order within 90 days of their first order.
-- Display the total number of customers (that placed at least one order) and the retention rate (as a percentage, formatted to two decimal places).
-- Use CTEs to first find the date of the first and second orders for each customer.
WITH customer_orders_ranked AS (
    SELECT
        cd.customer_unique_id,
        od.order_purchase_timestamp,
        ROW_NUMBER() OVER (PARTITION BY cd.customer_unique_id ORDER BY od.order_purchase_timestamp ASC) AS rank_num
    FROM
        olist_customers_dataset AS cd
    INNER JOIN
        olist_orders_dataset AS od ON cd.customer_id = od.customer_id
),
customer_first_second_orders AS (
    SELECT
        customer_unique_id,
        MIN(CASE WHEN rank_num = 1 THEN order_purchase_timestamp END) AS first_order_date,
        MIN(CASE WHEN rank_num = 2 THEN order_purchase_timestamp END) AS second_order_date
    FROM
        customer_orders_ranked
    GROUP BY
        customer_unique_id
)
SELECT
    COUNT(cfo.customer_unique_id) AS total_customers_with_orders,
    ROUND(
        SUM(CASE WHEN cfo.second_order_date <= cfo.first_order_date + INTERVAL '90 days' THEN 1 ELSE 0 END) * 100.0
        / COUNT(cfo.customer_unique_id),
    2) AS retention_rate_percentage
FROM
    customer_first_second_orders AS cfo
WHERE
    cfo.first_order_date IS NOT NULL;


-- Problem 2. Average Order Value by City and Month:
-- Calculate the Average Order Value (AOV) for each city on a monthly basis.
-- Only show cities that had an AOV greater than $150 for that specific month.
-- Display the customer_city, the year-month of the order, and the AOV.
SELECT
	cd.customer_city,
	TO_CHAR(od.order_purchase_timestamp, 'YYYY-MM') AS year_month,
	SUM(oid.price+oid.freight_value)/COUNT(DISTINCT od.order_id) AS aov
FROM
	olist_customers_dataset AS cd
INNER JOIN
	olist_orders_dataset AS od ON cd.customer_id=od.customer_id
INNER JOIN
	olist_order_items_dataset AS oid ON od.order_id=oid.order_id
GROUP BY
	cd.customer_city,
	year_month
HAVING
	SUM(oid.price+oid.freight_value)/COUNT(DISTINCT od.order_id) > 150
ORDER BY
	year_month,
    aov DESC;


-- Problem 3. Customer Loyalty Tiers:
-- Create loyalty tiers for all customers based on their total number of orders.
-- The tiers are:
-- Platinum (5 or more orders)
-- Gold (3-4 orders)
-- Silver (2 orders)
-- Bronze (1 order)
-- Display the customer_unique_id, the total_orders, and the loyalty_tier.
WITH total_orders_data AS (
	SELECT
		cd.customer_unique_id,
		COUNT(DISTINCT od.order_id) AS total_orders
	FROM
		olist_customers_dataset AS cd
	INNER JOIN
		olist_orders_dataset AS od ON cd.customer_id=od.customer_id
	GROUP BY
		cd.customer_unique_id
	ORDER BY total_orders DESC
)
SELECT
	customer_unique_id,
	total_orders,
	CASE
    WHEN total_orders >= 5 THEN 'Platinum'
    WHEN total_orders IN (3, 4) THEN 'Gold'
    WHEN total_orders = 2 THEN 'Silver'
    WHEN total_orders = 1 THEN 'Bronze'
    ELSE 'Unknown'
END AS loyalty_tier
FROM total_orders_data;