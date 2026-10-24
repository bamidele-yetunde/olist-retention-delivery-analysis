-- =====================================================================
--  16_seller_watchlist.sql  |  MySQL 8.0
--  Business question: which high-volume sellers have the worst late
--  rates and review scores, and how much do they deviate from their
--  peers?  (Candidates for an operations conversation.)
--
--  Techniques: CTE, HAVING to filter by volume, RANK() and
--  PERCENT_RANK() window functions, benchmarking against the
--  all-seller average with AVG() OVER ().
--  Depends on: fact_orders, order_items, sellers
-- =====================================================================
USE olist;

WITH seller_orders AS (                       -- one row per (seller, order)
  SELECT DISTINCT i.seller_id, f.order_id, f.is_late, f.review_score,
         f.shipped_after_limit, f.revenue
  FROM order_items i
  JOIN fact_orders f ON f.order_id = i.order_id
),
seller_stats AS (
  SELECT
    so.seller_id,
    s.seller_state,
    s.seller_city,
    COUNT(*)                                   AS orders,
    ROUND(SUM(revenue), 2)                     AS revenue_brl,
    ROUND(100 * AVG(is_late), 1)               AS pct_late,
    ROUND(100 * AVG(shipped_after_limit), 1)   AS pct_shipped_after_deadline,
    ROUND(AVG(review_score), 2)                AS avg_review_score,
    ROUND(100 * AVG(review_score = 1), 1)      AS pct_one_star
  FROM seller_orders so
  JOIN sellers s ON s.seller_id = so.seller_id
  GROUP BY so.seller_id, s.seller_state, s.seller_city
  HAVING COUNT(*) >= 100                        -- only sellers with real volume
)
SELECT
  RANK() OVER (ORDER BY pct_late DESC)                 AS late_rank,
  seller_id,
  seller_state,
  seller_city,
  orders,
  revenue_brl,
  pct_late,
  ROUND(pct_late - AVG(pct_late) OVER (), 1)           AS pct_late_vs_peer_avg,
  ROUND(100 * PERCENT_RANK() OVER (ORDER BY pct_late), 0) AS late_percentile,
  pct_shipped_after_deadline,
  avg_review_score,
  pct_one_star
FROM seller_stats
ORDER BY late_rank
LIMIT 25;
