/* ============================================================
   AB Test Analysis for Financial Market Strategies
   Table: financial_market_ab_test

   Columns (from CSV):
     - ticker            VARCHAR
     - date              DATE
     - price_before      DOUBLE
     - price_after       DOUBLE
     - volume_before     BIGINT
     - volume_after      BIGINT
     - strategy_version  CHAR(1)      -- 'A' (control) or 'B' (test)
     - market_condition  VARCHAR(20)  -- 'Bullish', 'Bearish', 'Sideways'
     - return_before     DOUBLE
     - return_after      DOUBLE
     - target            DOUBLE       -- main performance metric
   ============================================================ */


/* ============================================================
   1. BASIC SANITY CHECKS
   ============================================================ */

-- 1.1 Total rows in the experiment dataset
SELECT
  COUNT(*) AS total_rows
FROM financial_market_ab_test;

-- 1.2 Date range of the data
SELECT
  MIN(date) AS start_date,
  MAX(date) AS end_date,
  DATEDIFF(MAX(date), MIN(date)) + 1 AS num_days
FROM financial_market_ab_test;

-- 1.3 Distinct tickers and market conditions
SELECT
  COUNT(DISTINCT ticker)           AS num_tickers,
  COUNT(DISTINCT market_condition) AS num_market_conditions
FROM financial_market_ab_test;


/* ============================================================
   2. EXPERIMENT DESIGN CHECKS
   ============================================================ */

-- 2.1 Control vs Test size (group sizes)
SELECT
  strategy_version,
  COUNT(*) AS trades
FROM financial_market_ab_test
GROUP BY strategy_version;

-- 2.2 Experiment duration by strategy (overlap check)
SELECT
  strategy_version,
  MIN(date) AS start_date,
  MAX(date) AS end_date,
  COUNT(*)  AS trades
FROM financial_market_ab_test
GROUP BY strategy_version;

/* ============================================================
   3. BALANCE CHECKS (RANDOMIZATION VALIDATION)
   ============================================================ */

-- 3.1 Balance by ticker (trades per ticker per strategy)
SELECT
  ticker,
  strategy_version,
  COUNT(*) AS trades
FROM financial_market_ab_test
GROUP BY ticker, strategy_version
ORDER BY ticker, strategy_version;

-- 3.2 Balance by market condition (trades per regime per strategy)
SELECT
  market_condition,
  strategy_version,
  COUNT(*) AS trades
FROM financial_market_ab_test
GROUP BY market_condition, strategy_version
ORDER BY market_condition, strategy_version;


/* ============================================================
   4. EXPLORATORY DATA ANALYSIS (EDA)
   ============================================================ */

-- 4.1 Overall summary of target (all trades)
SELECT
  COUNT(*)            AS trades,
  AVG(target)         AS avg_target,
  MIN(target)         AS min_target,
  MAX(target)         AS max_target,
  STDDEV_SAMP(target) AS std_target
FROM financial_market_ab_test;

-- 4.2 Summary of target by strategy_version
SELECT
  strategy_version,
  COUNT(*)            AS trades,
  AVG(target)         AS avg_target,
  MIN(target)         AS min_target,
  MAX(target)         AS max_target,
  STDDEV_SAMP(target) AS std_target
FROM financial_market_ab_test
GROUP BY strategy_version;

-- 4.3 Bucket target values into return ranges (distribution view)
SELECT
  CASE
    WHEN target < -0.10 THEN '< -10%'
    WHEN target < -0.05 THEN '-10% to -5%'
    WHEN target <  0    THEN '-5% to 0%'
    WHEN target <  0.05 THEN '0% to 5%'
    WHEN target <  0.10 THEN '5% to 10%'
    ELSE '>= 10%'
  END AS target_bucket,
  COUNT(*) AS trades
FROM financial_market_ab_test
GROUP BY target_bucket
ORDER BY target_bucket;


/* ============================================================
   5. CORE A/B TEST METRICS (NSM & LIFT)
   ============================================================ */

-- 5.1 North Star Metric (NSM): average target per strategy
SELECT
  strategy_version,
  COUNT(*)    AS trades,
  AVG(target) AS avg_target
FROM financial_market_ab_test
GROUP BY strategy_version;

-- 5.2 Absolute and relative lift of Strategy B over Strategy A
WITH avg_by_version AS (
  SELECT
    strategy_version,
    AVG(target) AS avg_target
  FROM financial_market_ab_test
  GROUP BY strategy_version
)
SELECT
  b.avg_target                                              AS avg_target_B,
  a.avg_target                                              AS avg_target_A,
  (b.avg_target - a.avg_target)                             AS abs_lift,
  (b.avg_target - a.avg_target)
    / NULLIF(a.avg_target, 0) * 100                         AS rel_lift_percent
FROM avg_by_version a
JOIN avg_by_version b
  ON a.strategy_version = 'A'
 AND b.strategy_version = 'B';


/* ============================================================
   6. GUARDRAIL METRICS (RISK & EXECUTION)
   ============================================================ */

-- 6.1 Volatility and volume guardrails by strategy
SELECT
  strategy_version,
  COUNT(*)                AS trades,
  AVG(ABS(target))        AS avg_abs_return,
  STDDEV_SAMP(target)     AS return_volatility,
  AVG(volume_after)       AS avg_volume_after
FROM financial_market_ab_test
GROUP BY strategy_version;


/* ============================================================
   7. SEGMENT ANALYSIS (TICKER & MARKET CONDITION)
   ============================================================ */

-- 7.1 Per-ticker performance (return and risk)
SELECT
  ticker,
  strategy_version,
  COUNT(*)            AS trades,
  AVG(target)         AS avg_target,
  STDDEV_SAMP(target) AS std_target
FROM financial_market_ab_test
GROUP BY ticker, strategy_version
ORDER BY ticker, strategy_version;

-- 7.2 Per-market-condition performance (return and risk)
SELECT
  market_condition,
  strategy_version,
  COUNT(*)            AS trades,
  AVG(target)         AS avg_target,
  STDDEV_SAMP(target) AS std_target
FROM financial_market_ab_test
GROUP BY market_condition, strategy_version
ORDER BY market_condition, strategy_version;


/* ============================================================
   8. RISK-ADJUSTED PERFORMANCE (SHARPE-LIKE)
   ============================================================ */

-- 8.1 Simple Sharpe-like metric: mean return / standard deviation
SELECT
  strategy_version,
  AVG(target)         AS avg_target,
  STDDEV_SAMP(target) AS std_target,
  AVG(target) / NULLIF(STDDEV_SAMP(target), 0) AS sharpe_like
FROM financial_market_ab_test
GROUP BY strategy_version;


/* ============================================================
   9. APPROXIMATE 95% CONFIDENCE INTERVALS
   ============================================================ */

-- 9.1 95% confidence interval for mean target per strategy
SELECT
  strategy_version,
  COUNT(*)            AS n,
  AVG(target)         AS mean_target,
  STDDEV_SAMP(target) AS std_target,
  AVG(target) - 1.96 * STDDEV_SAMP(target)/SQRT(COUNT(*)) AS lower_95_ci,
  AVG(target) + 1.96 * STDDEV_SAMP(target)/SQRT(COUNT(*)) AS upper_95_ci
FROM financial_market_ab_test
GROUP BY strategy_version;


/* ============================================================
   10. SUMMARY STATS FOR EXTERNAL T-TESTING
   ============================================================ */

-- 10.1 Stats needed for a two-sample t-test 
SELECT
  strategy_version,
  COUNT(*)            AS n,
  AVG(target)         AS mean_target,
  STDDEV_SAMP(target) AS std_target
FROM financial_market_ab_test
GROUP BY strategy_version;
