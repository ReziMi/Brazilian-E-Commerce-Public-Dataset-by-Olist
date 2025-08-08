-- Customers Table
CREATE TABLE olist_customers_dataset (
    customer_id VARCHAR(50) PRIMARY KEY,
    customer_unique_id VARCHAR(50),
    customer_zip_code_prefix INTEGER,
    customer_city VARCHAR(100),
    customer_state VARCHAR(2)
);

-- Geolocation Table
CREATE TABLE olist_geolocation_dataset (
    geolocation_zip_code_prefix INTEGER,
    geolocation_lat DECIMAL(9,6),
    geolocation_lng DECIMAL(9,6),
    geolocation_city VARCHAR(100),
    geolocation_state VARCHAR(2)
);

-- Order Items Table
CREATE TABLE olist_order_items_dataset (
    order_id VARCHAR(50) NOT NULL,
    order_item_id INTEGER NOT NULL,
    product_id VARCHAR(50) NOT NULL, 
    seller_id VARCHAR(50) NOT NULL, 
    shipping_limit_date TIMESTAMP,
    price DECIMAL(10,2),
    freight_value DECIMAL(10,2),
    PRIMARY KEY (order_id, order_item_id)
);

-- Order Payments Table
CREATE TABLE olist_order_payments_dataset (
    order_id VARCHAR(50) NOT NULL, 
    payment_sequential INTEGER NOT NULL,
    payment_type VARCHAR(50),
    payment_installments INTEGER,
    payment_value DECIMAL(10,2),
    PRIMARY KEY (order_id, payment_sequential)
);

-- Order Reviews Table
CREATE TABLE olist_order_reviews_dataset (
    review_id VARCHAR(50) PRIMARY KEY,
    order_id VARCHAR(50) NOT NULL,
    review_score INTEGER,
    review_comment_title TEXT,
    review_comment_message TEXT,
    review_creation_date TIMESTAMP,
    review_answer_timestamp TIMESTAMP
);

-- Orders Table
CREATE TABLE olist_orders_dataset (
    order_id VARCHAR(50) PRIMARY KEY,
    customer_id VARCHAR(50) NOT NULL, 
    order_status VARCHAR(50),
    order_purchase_timestamp TIMESTAMP,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP
);

-- Products Table
CREATE TABLE olist_products_dataset (
    product_id VARCHAR(50) PRIMARY KEY,
    product_category_name VARCHAR(100), 
    product_name_length INTEGER,
    product_description_length INTEGER,
    product_photos_qty INTEGER,
    product_weight_g INTEGER,
    product_length_cm INTEGER,
    product_height_cm INTEGER,
    product_width_cm INTEGER
);

-- Sellers Table
CREATE TABLE olist_sellers_dataset (
    seller_id VARCHAR(50) PRIMARY KEY,
    seller_zip_code_prefix INTEGER,
    seller_city VARCHAR(100),
    seller_state VARCHAR(2)
);

-- Product Category Name Translation Table
CREATE TABLE product_category_name_translation (
    product_category_name VARCHAR(100) PRIMARY KEY,
    product_category_name_english VARCHAR(100)
);

ALTER TABLE olist_orders_dataset
ADD CONSTRAINT fk_customer FOREIGN KEY (customer_id) REFERENCES olist_customers_dataset(customer_id);

ALTER TABLE olist_order_items_dataset
ADD CONSTRAINT fk_order FOREIGN KEY (order_id) REFERENCES olist_orders_dataset(order_id);

ALTER TABLE olist_order_items_dataset
ADD CONSTRAINT fk_seller FOREIGN KEY (seller_id) REFERENCES olist_sellers_dataset(seller_id);

ALTER TABLE olist_order_payments_dataset
ADD CONSTRAINT fk_payment_order FOREIGN KEY (order_id) REFERENCES olist_orders_dataset(order_id);

ALTER TABLE olist_order_reviews_dataset
ADD CONSTRAINT fk_review_order FOREIGN KEY (order_id) REFERENCES olist_orders_dataset(order_id);

ALTER TABLE olist_products_dataset
ADD CONSTRAINT fk_product_category FOREIGN KEY (product_category_name) REFERENCES product_category_name_translation(product_category_name);

SELECT current_database();

SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public' AND table_type = 'BASE TABLE';

SELECT COUNT(*) FROM olist_customers_dataset;
SELECT COUNT(*) FROM olist_geolocation_dataset;
SELECT COUNT(*) FROM olist_order_items_dataset;
SELECT COUNT(*) FROM olist_order_payments_dataset;
SELECT COUNT(*) FROM olist_order_reviews_dataset;
SELECT COUNT(*) FROM olist_orders_dataset;
SELECT COUNT(*) FROM olist_products_dataset;
SELECT COUNT(*) FROM olist_sellers_dataset;
SELECT COUNT(*) FROM product_category_name_translation;

TRUNCATE TABLE olist_order_reviews_dataset RESTART IDENTITY CASCADE;
ALTER TABLE olist_products_dataset DROP CONSTRAINT fk_product_category;
TRUNCATE TABLE olist_products_dataset RESTART IDENTITY CASCADE;

TRUNCATE TABLE olist_order_reviews_dataset;

CREATE TEMP TABLE temp_reviews (
  review_id TEXT,
  order_id TEXT,
  review_score INTEGER,
  review_comment_title TEXT,
  review_comment_message TEXT,
  review_creation_date TIMESTAMP,
  review_answer_timestamp TIMESTAMP
);

ALTER TABLE olist_order_reviews_dataset DROP CONSTRAINT olist_order_reviews_dataset_pkey;

DELETE FROM olist_order_reviews_dataset
WHERE ctid IN (
    SELECT ctid
    FROM (
        SELECT
            ctid, -- PostgreSQL's internal row identifier
            review_id,
            -- Add review_answer_timestamp to ORDER BY for consistent tie-breaking if creation dates are the same
            ROW_NUMBER() OVER (PARTITION BY review_id ORDER BY review_creation_date, review_answer_timestamp) AS rn
        FROM olist_order_reviews_dataset
    ) AS duplicates_to_delete
    WHERE rn > 1
);

SELECT review_id, COUNT(*)
FROM olist_order_reviews_dataset
GROUP BY review_id
HAVING COUNT(*) > 1;


-- Day 1: Foundation - Schema, Core Joins, & Basic Aggregations

-- 1. Count the number of rows in all olist_ tables:
--    olist_customers_dataset, olist_orders_dataset, olist_order_items_dataset,
--    olist_products_dataset, olist_sellers_dataset, olist_order_payments_dataset,
--    olist_order_reviews_dataset, product_category_name_translation, olist_geolocation_dataset.
SELECT 'olist_customers_dataset' AS table_name, COUNT(*) FROM olist_customers_dataset
UNION ALL
SELECT 'olist_orders_dataset', COUNT(*) FROM olist_orders_dataset
UNION ALL
SELECT 'olist_order_items_dataset', COUNT(*) FROM olist_order_items_dataset
UNION ALL
SELECT 'olist_products_dataset', COUNT(*) FROM olist_products_dataset
UNION ALL
SELECT 'olist_sellers_dataset', COUNT(*) FROM olist_sellers_dataset
UNION ALL
SELECT 'olist_order_payments_dataset', COUNT(*) FROM olist_order_payments_dataset
UNION ALL
SELECT 'olist_order_reviews_dataset', COUNT(*) FROM olist_order_reviews_dataset
UNION ALL
SELECT 'product_category_name_translation', COUNT(*) FROM product_category_name_translation
UNION ALL
SELECT 'olist_geolocation_dataset', COUNT(*) FROM olist_geolocation_dataset;


-- 2. What are the counts for each order_status in the olist_orders_dataset table?
SELECT order_status,
	count(order_status) AS status_count
FROM olist_orders_dataset
GROUP BY order_status
ORDER BY status_count desc;

-- 3. How many unique customer_unique_ids are there in olist_customers_dataset?
--    How many unique seller_ids are there in olist_sellers_dataset?
SELECT 
  (SELECT COUNT(DISTINCT customer_unique_id) FROM olist_customers_dataset) AS unique_customers,
  (SELECT COUNT(DISTINCT seller_id) FROM olist_sellers_dataset) AS unique_sellers;


-- 4. Calculate the total number of items sold (use count of order_item_id as proxy)
--    AND the total revenue (sum of price + freight_value) across all sales from olist_order_items_dataset.
SELECT 
    COUNT(order_item_id) AS total_items_sold,
    SUM(price + freight_value) AS total_revenue
FROM olist_order_items_dataset;



-- 5. Count the number of orders originating from each customer_state.
--    (Join olist_orders_dataset with olist_customers_dataset on customer_id)
-- solution 1
WITH orders_from_state AS(
	SELECT 
		c.customer_state,
		o.order_id
	FROM olist_orders_dataset AS o
	INNER JOIN
	    olist_customers_dataset AS c ON o.customer_id = c.customer_id
)
SELECT
	customer_state,
	count(order_id) as order_number
FROM orders_from_state
GROUP BY customer_state
ORDER BY order_number DESC;

-- solution 2
SELECT 
    c.customer_state,
    COUNT(o.order_id) AS order_number
FROM olist_orders_dataset o
JOIN olist_customers_dataset c ON o.customer_id = c.customer_id
GROUP BY c.customer_state
ORDER BY order_number DESC;


-- 6. List each payment_type and the count of unique orders associated with it
--    from olist_order_payments_dataset.
SELECT payment_type,
	COUNT(DISTINCT order_id) AS count_unique_orders
FROM olist_order_payments_dataset
GROUP BY payment_type
ORDER BY count_unique_orders DESC;

-- 7. Calculate the total revenue generated by each seller_id
--    (sum of price + freight_value from olist_order_items_dataset).
--    List the top 10 sellers by total revenue, in descending order.

SELECT 
	seller_id,
	SUM(price+freight_value) AS total_revenue
FROM olist_order_items_dataset
GROUP BY seller_id
ORDER BY total_revenue DESC
LIMIT 10;
