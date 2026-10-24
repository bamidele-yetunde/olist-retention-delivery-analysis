-- =====================================================================
--  04_create_views_and_fact_table.sql  |  MySQL 8.0
--  Builds the order-level analytical layer every later query uses.
--
--  v_order_facts   one row per order, with every delivery/review metric
--  fact_orders     materialised copy of v_order_facts restricted to the
--                  analysis population (fast, and what Power BI reads)
--
--  Definitions (used identically in SQL, Python, Power BI and Excel)
--   delay_days      = delivered date - promised date (calendar days;
--                     negative = early, 0 = on the day, > 0 = late)
--   is_late         = delay_days > 0
--   delivery_days   = purchase -> delivered, in days (decimal)
--   promised_days   = purchase -> promised date
--   handling_days   = approved -> handed to carrier   (seller's part)
--   transit_days    = handed to carrier -> delivered  (carrier's part)
--   revenue         = SUM(item price), freight shown separately
--   review_score    = latest review for the order (555 orders have two)
--
--  Analysis population: status = 'delivered', delivery date present,
--  purchased 2017-01-01 .. 2018-08-31 (20 full months).
-- =====================================================================
USE olist;

CREATE OR REPLACE VIEW v_order_facts AS
WITH items AS (
  SELECT order_id,
         SUM(price)                  AS revenue,
         SUM(freight_value)          AS freight,
         COUNT(*)                    AS n_items,
         COUNT(DISTINCT seller_id)   AS n_sellers,
         MAX(shipping_limit_date)    AS shipping_limit_date
  FROM order_items
  GROUP BY order_id
),
latest_review AS (
  SELECT order_id, review_score
  FROM (
    SELECT order_id, review_score,
           ROW_NUMBER() OVER (PARTITION BY order_id
                              ORDER BY review_answer_timestamp DESC, review_id) AS rn
    FROM order_reviews
  ) r
  WHERE rn = 1
),
main_item AS (                       -- the order's most expensive line = its "main" category
  SELECT order_id, product_id, seller_id
  FROM (
    SELECT order_id, product_id, seller_id,
           ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY price DESC, order_item_id) AS rn
    FROM order_items
  ) x
  WHERE rn = 1
)
SELECT
  o.order_id,
  o.customer_id,
  c.customer_unique_id,
  c.customer_state,
  c.customer_zip_code_prefix,
  s.seller_state                                   AS main_seller_state,
  mi.seller_id                                     AS main_seller_id,
  COALESCE(t.product_category_name_english,
           p.product_category_name, 'unknown')     AS main_category,
  o.order_status,
  o.order_purchase_timestamp,
  o.order_approved_at,
  o.order_delivered_carrier_date,
  o.order_delivered_customer_date,
  o.order_estimated_delivery_date,
  DATEDIFF(o.order_delivered_customer_date, o.order_estimated_delivery_date)          AS delay_days,
  CASE WHEN DATEDIFF(o.order_delivered_customer_date, o.order_estimated_delivery_date) > 0
       THEN 1 ELSE 0 END                                                              AS is_late,
  ROUND(TIMESTAMPDIFF(MINUTE, o.order_purchase_timestamp, o.order_delivered_customer_date) / 1440, 2) AS delivery_days,
  ROUND(TIMESTAMPDIFF(MINUTE, o.order_purchase_timestamp, o.order_estimated_delivery_date) / 1440, 2) AS promised_days,
  ROUND(TIMESTAMPDIFF(MINUTE, o.order_approved_at, o.order_delivered_carrier_date) / 1440, 2)         AS handling_days,
  ROUND(TIMESTAMPDIFF(MINUTE, o.order_delivered_carrier_date, o.order_delivered_customer_date) / 1440, 2) AS transit_days,
  CASE WHEN o.order_delivered_carrier_date > i.shipping_limit_date THEN 1 ELSE 0 END  AS shipped_after_limit,
  i.revenue,
  i.freight,
  i.n_items,
  i.n_sellers,
  r.review_score
FROM orders o
JOIN customers c           ON c.customer_id = o.customer_id
LEFT JOIN items i          ON i.order_id    = o.order_id
LEFT JOIN latest_review r  ON r.order_id    = o.order_id
LEFT JOIN main_item mi     ON mi.order_id   = o.order_id
LEFT JOIN sellers s        ON s.seller_id   = mi.seller_id
LEFT JOIN products p       ON p.product_id  = mi.product_id
LEFT JOIN product_category_translation t ON t.product_category_name = p.product_category_name;

-- Materialise the analysis population ------------------------------------
DROP TABLE IF EXISTS fact_orders;

CREATE TABLE fact_orders AS
SELECT *
FROM v_order_facts
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL
  AND order_purchase_timestamp >= '2017-01-01'
  AND order_purchase_timestamp <  '2018-09-01';

ALTER TABLE fact_orders
  ADD PRIMARY KEY (order_id),
  ADD KEY ix_fact_customer (customer_unique_id),
  ADD KEY ix_fact_state    (customer_state),
  ADD KEY ix_fact_purchase (order_purchase_timestamp),
  ADD KEY ix_fact_late     (is_late);

SELECT COUNT(*)                                  AS delivered_orders_in_window,
       ROUND(100 * AVG(is_late), 2)              AS pct_late,
       ROUND(AVG(review_score), 2)               AS avg_review_score,
       ROUND(SUM(revenue), 2)                    AS revenue_brl
FROM fact_orders;
