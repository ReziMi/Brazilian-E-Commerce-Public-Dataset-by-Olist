-- Day 3: Advanced - Window Functions, CTEs, & Performance Considerations

-- Goal: Master advanced SQL concepts to perform complex analytical tasks,
--       including ranking, running calculations, and efficient data manipulation.

-- Key Concepts for Today: ROW_NUMBER(), RANK(), DENSE_RANK(), PARTITION BY, OVER(),
--                         LAG(), LEAD(), NTILE(), more complex CTEs, and optimizing multi-step logic.


-- Problem 1. Top Customers by Total Spend: 
-- Rank all customer_unique_id's based on their total spending (sum of price + freight_value) across all their orders.
-- Include their customer_unique_id, their total spend, and their rank.
-- Use DENSE_RANK() for ranking.
SELECT
	cd.customer_unique_id,
	SUM(oid.price+oid.freight_value) AS total_spending,
	DENSE_RANK() OVER (
    ORDER BY SUM(oid.price + oid.freight_value) DESC
  ) AS spending_rank
FROM olist_customers_dataset AS cd
INNER JOIN
	olist_orders_dataset AS od ON od.customer_id=cd.customer_id
INNER JOIN
	olist_order_items_dataset AS oid ON oid.order_id=od.order_id
GROUP BY cd.customer_unique_id
ORDER BY spending_rank;

-- Problem 2. Monthly Revenue Growth Rate:
-- Calculate the month-over-month percentage growth in total revenue.
-- Display the year, month, total revenue for that month, previous month's total revenue, and the growth rate percentage.
-- The formula for growth rate is: ((Current Month Revenue - Previous Month Revenue) / Previous Month Revenue) * 100.
-- Handle the first month (where there's no previous month) gracefully (e.g., show NULL for previous revenue and growth rate).
WITH monthly_revenue AS (
  SELECT
    DATE_TRUNC('month', o.order_purchase_timestamp) AS order_month,
    SUM(oi.price + oi.freight_value) AS monthly_revenue
  FROM
    olist_orders_dataset AS o
  INNER JOIN
    olist_order_items_dataset AS oi ON o.order_id = oi.order_id
  GROUP BY
    1
)
SELECT
  TO_CHAR(order_month, 'YYYY-MM') AS year_month,
  monthly_revenue AS current_month_revenue,
  LAG(monthly_revenue, 1) OVER (
    ORDER BY order_month
  ) AS previous_month_revenue,
  (
    (monthly_revenue - LAG(monthly_revenue, 1) OVER (ORDER BY order_month)) / LAG(monthly_revenue, 1) OVER (ORDER BY order_month)
  ) * 100 AS growth_rate_percentage
FROM
  monthly_revenue
ORDER BY
  order_month;

-- Problem 3. Top Sellers Within Each Product Category:
-- For each translated product category, rank sellers by their total revenue within that specific category.
-- Display the product_category_name_english, seller_id, total revenue in that category, and their rank within the category.
-- List only the top 3 sellers for each category. Use ROW_NUMBER().
WITH seller_category_revenue AS (
  SELECT
    pct.product_category_name_english,
    oi.seller_id,
    SUM(oi.price + oi.freight_value) AS total_revenue
  FROM
    product_category_name_translation AS pct
  INNER JOIN
    olist_products_dataset AS p ON p.product_category_name = pct.product_category_name
  INNER JOIN
    olist_order_items_dataset AS oi ON oi.product_id = p.product_id
  GROUP BY
    pct.product_category_name_english,
    oi.seller_id
),
ranked_sellers AS (
  SELECT
    product_category_name_english,
    seller_id,
    total_revenue,
    ROW_NUMBER() OVER (
      PARTITION BY product_category_name_english
      ORDER BY total_revenue DESC
    ) AS rank_within_category
  FROM
    seller_category_revenue
)
SELECT
  product_category_name_english,
  seller_id,
  total_revenue,
  rank_within_category
FROM
  ranked_sellers
WHERE
  rank_within_category <= 3
ORDER BY
  product_category_name_english,
  rank_within_category;

-- Problem 4. First Order Date for Each Customer:
-- For each customer_unique_id, find the earliest order_purchase_timestamp.
-- Display customer_unique_id and their first order date.

-- solution 1
WITH sales_timestamp AS (
	SELECT cd.customer_unique_id,
		od.order_purchase_timestamp
	FROM olist_customers_dataset AS cd
	INNER JOIN
		olist_orders_dataset AS od ON cd.customer_id=od.customer_id
),
ranked_purchases AS(
SELECT
	customer_unique_id,
	order_purchase_timestamp,
	ROW_NUMBER() OVER (
      PARTITION BY customer_unique_id
      ORDER BY order_purchase_timestamp
    ) AS timestamp_rank
  FROM
    sales_timestamp
)
SELECT 
	customer_unique_id,
	order_purchase_timestamp
FROM ranked_purchases
	WHERE timestamp_rank=1;

-- solution 2
SELECT
    cd.customer_unique_id,
    MIN(od.order_purchase_timestamp) AS first_order_date
FROM
    olist_customers_dataset AS cd
INNER JOIN
    olist_orders_dataset AS od ON cd.customer_id = od.customer_id
GROUP BY
    cd.customer_unique_id;

	
-- Problem 5. Orders with Multiple Distinct Products from Same Seller:
-- Identify order_id's where a single seller sold multiple *distinct* products within that same order.
-- List the order_id, seller_id, and the count of distinct products that seller sold in that order.
SELECT
    order_id,
    seller_id,
    COUNT(DISTINCT product_id) AS product_count
FROM
    olist_order_items_dataset
GROUP BY
    seller_id, order_id
HAVING
    COUNT(DISTINCT product_id) > 1;

-- Problem 6. Average Order Value (AOV) per Customer State per Month:
-- Calculate the Average Order Value (AOV), defined as total revenue (price + freight_value) per order,
-- for each customer_state, for each month.
-- Display customer_state, year-month (YYYY-MM format), total revenue for that state-month,
-- total number of orders for that state-month, and the calculated AOV.
-- Order chronologically by year-month, then by customer_state.
SELECT
    c.customer_state,
    TO_CHAR(o.order_purchase_timestamp, 'YYYY-MM') AS year_month,
    SUM(oi.price + oi.freight_value) AS total_revenue_for_group,
    COUNT(DISTINCT o.order_id) AS total_orders_for_group,
    SUM(oi.price + oi.freight_value) / COUNT(DISTINCT o.order_id) AS aov
FROM
    olist_customers_dataset AS c
INNER JOIN
    olist_orders_dataset AS o ON o.customer_id = c.customer_id
INNER JOIN
    olist_order_items_dataset AS oi ON oi.order_id = o.order_id
GROUP BY
    c.customer_state,
    year_month
ORDER BY
    year_month,
    c.customer_state;
	


-- Problem 7. Customers Buying Diverse Products from Different Sellers:
-- Find customer_unique_id's who have purchased products from the *same broad product category*
-- (e.g., 'electronics' or 'fashion') but from *different sellers* across their purchases.
-- List the customer_unique_id, the product_category_name_english, and the count of distinct sellers they bought from in that category.
-- Only include results where the customer bought from more than one distinct seller for that category.

SELECT
    c.customer_unique_id,
    pct.product_category_name_english,
    COUNT(DISTINCT oi.seller_id) AS distinct_sellers_count
FROM
    olist_customers_dataset AS c
INNER JOIN
    olist_orders_dataset AS o ON c.customer_id = o.customer_id
INNER JOIN
    olist_order_items_dataset AS oi ON o.order_id = oi.order_id
INNER JOIN
    olist_products_dataset AS p ON p.product_id = oi.product_id
INNER JOIN
    product_category_name_translation AS pct ON pct.product_category_name = p.product_category_name
GROUP BY
    c.customer_unique_id,
    pct.product_category_name_english
HAVING
    COUNT(DISTINCT oi.seller_id) > 1
ORDER BY
    distinct_sellers_count DESC,
    c.customer_unique_id;
