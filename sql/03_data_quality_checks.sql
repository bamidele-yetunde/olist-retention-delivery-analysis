-- =====================================================================
--  03_data_quality_checks.sql  |  MySQL 8.0
--  Question: can this data be trusted, and which rows should the
--  analysis exclude?  Run after loading; every block is independent.
--
--  Findings this script surfaces (and how the analysis handles them):
--   1. 8 orders are 'delivered' but have no delivery date  -> excluded
--   2. 802 review_ids are reused across orders (827 extra rows) -> composite key
--   3. 555 orders have more than one review                -> keep the latest
--   4. 775 orders have no line items (cancelled/unavailable)-> no revenue
--   5. 610 products have no category, 13 more (2 category
--      names) have no English translation                 -> 'unknown' / Portuguese name
--   6. Sep-Dec 2016 and Sep-Oct 2018 have almost no orders  -> analysis
--      window is Jan 2017 - Aug 2018 (20 complete months)
-- =====================================================================
USE olist;

-- 1. Row counts vs the Kaggle documentation
SELECT 'orders' AS tbl, COUNT(*) AS rows_loaded, 99441 AS rows_expected FROM orders
UNION ALL SELECT 'order_items',    COUNT(*), 112650 FROM order_items
UNION ALL SELECT 'order_payments', COUNT(*), 103886 FROM order_payments
UNION ALL SELECT 'order_reviews',  COUNT(*), 100000 FROM order_reviews
UNION ALL SELECT 'customers',      COUNT(*), 99441  FROM customers
UNION ALL SELECT 'products',       COUNT(*), 32951  FROM products
UNION ALL SELECT 'sellers',        COUNT(*), 3095   FROM sellers;

-- 2. Order status mix: only 'delivered' orders can be judged on delivery
SELECT order_status,
       COUNT(*)                                        AS orders,
       ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct
FROM orders
GROUP BY order_status
ORDER BY orders DESC;

-- 3. Missing timestamps, and the contradiction: delivered but no date
SELECT
  SUM(order_approved_at IS NULL)                                  AS missing_approved,
  SUM(order_delivered_carrier_date IS NULL)                       AS missing_carrier_date,
  SUM(order_delivered_customer_date IS NULL)                      AS missing_delivered_date,
  SUM(order_status = 'delivered'
      AND order_delivered_customer_date IS NULL)                  AS delivered_but_no_date
FROM orders;

-- 4. Reviews: duplicated ids and orders with several reviews
SELECT
  (SELECT COUNT(*) - COUNT(DISTINCT review_id) FROM order_reviews) AS extra_rows_from_duplicate_review_ids,
  (SELECT COUNT(*) FROM (SELECT review_id FROM order_reviews
                         GROUP BY review_id HAVING COUNT(*) > 1) d) AS review_ids_on_multiple_orders,
  (SELECT COUNT(*) FROM (SELECT order_id FROM order_reviews
                         GROUP BY order_id HAVING COUNT(*) > 1) x) AS orders_with_multiple_reviews;

-- 5. Referential integrity (all should be zero thanks to the FKs)
SELECT
  (SELECT COUNT(*) FROM orders o LEFT JOIN order_items i USING (order_id)
    WHERE i.order_id IS NULL)                                      AS orders_without_items,
  (SELECT COUNT(*) FROM orders o LEFT JOIN order_payments p USING (order_id)
    WHERE p.order_id IS NULL)                                      AS orders_without_payment,
  (SELECT COUNT(*) FROM orders o LEFT JOIN order_reviews r USING (order_id)
    WHERE r.order_id IS NULL)                                      AS orders_without_review,
  (SELECT COUNT(*) FROM products WHERE product_category_name IS NULL) AS products_without_category,
  (SELECT COUNT(*) FROM products p
     LEFT JOIN product_category_translation t USING (product_category_name)
    WHERE p.product_category_name IS NOT NULL AND t.product_category_name IS NULL)
                                                                   AS products_without_translation;

-- 6. Volume by month: justifies the analysis window (Jan 2017 - Aug 2018)
SELECT DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS order_month,
       COUNT(*)                                       AS orders
FROM orders
GROUP BY order_month
ORDER BY order_month;

-- 7. Sanity ranges
SELECT MIN(order_purchase_timestamp) AS first_order,
       MAX(order_purchase_timestamp) AS last_order,
       MIN(price) AS min_price, MAX(price) AS max_price,
       MIN(freight_value) AS min_freight, MAX(freight_value) AS max_freight
FROM orders JOIN order_items USING (order_id);
