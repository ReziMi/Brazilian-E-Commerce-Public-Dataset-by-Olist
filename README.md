# 7-Day SQL Challenge: Brazilian E-Commerce Dataset

## Overview

This repository contains SQL scripts for a 7-Day SQL Challenge designed to enhance SQL proficiency using the Brazilian E-Commerce Public Dataset by Olist. The challenge progresses from foundational to advanced SQL techniques, including schema creation, joins, aggregations, window functions, CTEs, and date/time analysis, applied to real-world e-commerce data.

The dataset includes ~100,000 anonymized orders from 2016–2018 across Brazilian marketplaces, covering orders, customers, products, payments, reviews, sellers, and geolocation.

---

## Dataset

The Brazilian E-Commerce Public Dataset by Olist (available on Kaggle) includes the following tables:

- `olist_customers_dataset`: Customer details (ID, unique ID, zip code, city, state)
- `olist_geolocation_dataset`: Zip code to lat/long mappings
- `olist_order_items_dataset`: Order items (order ID, product ID, seller ID, price, freight)
- `olist_order_payments_dataset`: Payment info (order ID, payment type, value)
- `olist_order_reviews_dataset`: Customer reviews (review ID, order ID, score, comments)
- `olist_orders_dataset`: Order details (ID, customer ID, status, timestamps)
- `olist_products_dataset`: Product info (ID, category, dimensions, weight)
- `olist_sellers_dataset`: Seller details (ID, zip code, city, state)
- `product_category_name_translation`: Portuguese to English category names

**Note**: Data is anonymized, with company references replaced by Game of Thrones house names.

---

## Challenge Structure

The challenge spans seven days, each focusing on specific SQL skills:

### Day 1: Foundation

- **Focus**: Schema creation, basic joins, and aggregations  
- **Tasks**: Count orders by status, calculate total revenue, analyze orders by state

### Day 2: Intermediate

- **Focus**: Complex joins, subqueries, date functions (`TO_CHAR`, `DATE_TRUNC`)  
- **Tasks**: Identify orders without reviews, track monthly sales, find sellers with diverse categories

### Day 3: Advanced

- **Focus**: Window functions (`ROW_NUMBER`, `RANK`, `LAG`) and CTEs  
- **Tasks**: Rank customers by spend, calculate revenue growth, find top sellers per category

### Day 4: Synthesis

- **Focus**: Combine joins, subqueries, CTEs, and window functions  
- **Tasks**: Analyze payment types over time, calculate cancellation rates, review on-time deliveries

### Day 5: Business Questions

- **Focus**: High-level business problems  
- **Tasks**: Monthly sales by state, customer acquisition cohorts, seller performance by reviews

### Day 6: Date and Time Analysis

- **Focus**: Advanced date/time manipulations  
- **Tasks**: Delivery times by weekday, late order rates, customer growth by region

### Day 7: Final Insights

- **Focus**: Complex business problems  
- **Tasks**: Customer retention, AOV by city, loyalty tiers, top-rated products


---

## Prerequisites

- **Database**: PostgreSQL  
- **Tools**: SQL client (e.g., pgAdmin, DBeaver, psql)  
- **Dataset**: Olist Brazilian E-Commerce Dataset

---

## Learning Outcomes

- Master SQL schema design and data cleaning  
- Gain expertise in joins, aggregations, subqueries, and window functions  
- Develop skills in date/time analysis
