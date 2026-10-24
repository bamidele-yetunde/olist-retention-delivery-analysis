-- =====================================================================
--  12_review_score_vs_delay.sql  |  MySQL 8.0
--  Business question: how fast does customer satisfaction collapse once
--  an order misses its promised date?
--
--  Techniques: CASE bucketing, conditional aggregation, ordering buckets
--  with a sort key.
--  Depends on: fact_orders
--
--  Reading the result: average score is 4.3 for early/on-time orders,
--  drops to ~3.3 at 1-3 days late and ~2.1 at 4-7 days late. More than
--  half of orders that are 4+ days late get a 1-star review.
-- =====================================================================
USE olist;

SELECT
  CASE
    WHEN delay_days <= -8            THEN '1. 8+ days early'
    WHEN delay_days <= 0             THEN '2. on time (0-7 days early)'
    WHEN delay_days BETWEEN 1  AND 3 THEN '3. 1-3 days late'
    WHEN delay_days BETWEEN 4  AND 7 THEN '4. 4-7 days late'
    WHEN delay_days BETWEEN 8  AND 14 THEN '5. 8-14 days late'
    ELSE                                  '6. 15+ days late'
  END                                                AS delay_bucket,
  COUNT(*)                                           AS orders,
  ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 2)   AS pct_of_orders,
  ROUND(AVG(review_score), 2)                        AS avg_review_score,
  ROUND(100 * AVG(review_score = 1), 1)              AS pct_one_star,
  ROUND(100 * AVG(review_score <= 2), 1)             AS pct_one_or_two_star,
  ROUND(100 * AVG(review_score >= 4), 1)             AS pct_four_or_five_star,
  ROUND(SUM(revenue), 2)                             AS revenue_brl
FROM fact_orders
WHERE review_score IS NOT NULL
GROUP BY delay_bucket
ORDER BY delay_bucket;
