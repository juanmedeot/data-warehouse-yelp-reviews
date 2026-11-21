/*
===============================================================================
Data Quality & Dimensional Integrity Checks - Gold Layer
===============================================================================
Script Purpose: 
    This script performs dimensional and referential integrity checks on the 
    Gold layer materialized views after loading from the Silver layer.

    It focuses on Gold-specific concerns rather than repeating Silver raw data 
    cleaning/type tests:
    1. Row count & Unknown (-1) member presence in dimensions and fact table.
    2. Surrogate key and composite grain uniqueness across all Gold tables.
    3. Foreign key referential integrity and orphan (-1) fallback rate.
    4. Gold business logic rules (business hours durations, 24h flag, midnight
       crossings, and elite year boundaries).

How to run:
    This script uses psql meta-commands (\echo).

    From terminal:
    psql -h <host> -U <user> -d datawarehouse -f "path\gold_layer_test.sql"

===============================================================================
*/

\echo '====================================================='
\echo 'STARTING DATA QUALITY TESTS: GOLD LAYER'
\echo '====================================================='

-- 1. Row Count & Unknown (-1) Member Checks on Dimensions and Fact Table
\echo '>> Test 1A: dim_user Row Count (Expected: silver.yelp_user + 1 for UNKNOWN -1)'
\echo '>> Expected Result: 0'
SELECT (SELECT COUNT(*) FROM gold.dim_user) - ((SELECT COUNT(*) FROM silver.yelp_user) + 1) AS dim_user_count_diff;

\echo '>> Test 1B: dim_business Row Count (Expected: silver.yelp_business + 1 for UNKNOWN -1)'
\echo '>> Expected Result: 0'
SELECT (SELECT COUNT(*) FROM gold.dim_business) - ((SELECT COUNT(*) FROM silver.yelp_business) + 1) AS dim_business_count_diff;

\echo '>> Test 1C: fact_review Row Count (Expected: exact match with silver.yelp_review)'
\echo '>> Expected Result: 0'
SELECT (SELECT COUNT(*) FROM gold.fact_review) - (SELECT COUNT(*) FROM silver.yelp_review) AS fact_review_count_diff;

\echo '>> Test 1D: Verify Unknown (-1) Members Exist in Core Dimensions'
\echo '>> Expected Result: 0'
SELECT
    (CASE WHEN EXISTS (SELECT 1 FROM gold.dim_user WHERE user_key = -1 AND user_id = 'UNKNOWN') THEN 0 ELSE 1 END) +
    (CASE WHEN EXISTS (SELECT 1 FROM gold.dim_business WHERE business_key = -1 AND business_id = 'UNKNOWN') THEN 0 ELSE 1 END)
    AS missing_unknown_members;

---

-- 2. Primary Key & Grain Uniqueness Checks
\echo '>> Test 2A: Duplicate Surrogate / Composite Keys Across Gold Tables'
\echo '>> Expected Result: 0'
SELECT
    (SELECT COUNT(*) FROM (SELECT user_key FROM gold.dim_user GROUP BY user_key HAVING COUNT(*) > 1) t) +
    (SELECT COUNT(*) FROM (SELECT business_key FROM gold.dim_business GROUP BY business_key HAVING COUNT(*) > 1) t) +
    (SELECT COUNT(*) FROM (SELECT review_key FROM gold.fact_review GROUP BY review_key HAVING COUNT(*) > 1) t) +
    (SELECT COUNT(*) FROM (SELECT user_key, friend_user_id FROM gold.dim_user_friend GROUP BY user_key, friend_user_id HAVING COUNT(*) > 1) t) +
    (SELECT COUNT(*) FROM (SELECT user_key, elite_year FROM gold.dim_user_elite GROUP BY user_key, elite_year HAVING COUNT(*) > 1) t) +
    (SELECT COUNT(*) FROM (SELECT business_key, category_name FROM gold.dim_business_category GROUP BY business_key, category_name HAVING COUNT(*) > 1) t) +
    (SELECT COUNT(*) FROM (SELECT business_key, day_number FROM gold.dim_business_hours GROUP BY business_key, day_number HAVING COUNT(*) > 1) t)
    AS total_duplicate_keys;

---

-- 3. Referential Integrity & Orphan (-1) Fallback Rate
\echo '>> Test 3A: NULL Foreign Keys in Gold Child & Fact Tables'
\echo '>> Expected Result: 0'
SELECT COUNT(*) AS null_fk_count
FROM (
    SELECT 1 FROM gold.dim_user_friend WHERE user_key IS NULL
    UNION ALL
    SELECT 1 FROM gold.dim_user_elite WHERE user_key IS NULL
    UNION ALL
    SELECT 1 FROM gold.dim_business_category WHERE business_key IS NULL
    UNION ALL
    SELECT 1 FROM gold.dim_business_hours WHERE business_key IS NULL
    UNION ALL
    SELECT 1 FROM gold.fact_review WHERE user_key IS NULL OR business_key IS NULL
) f;

\echo '>> Test 3B: Broken Foreign Keys (FKs Not Present in Parent Dimension)'
\echo '>> Expected Result: 0'
SELECT COUNT(*) AS broken_fk_count
FROM (
    SELECT 1 FROM gold.dim_user_friend f
    WHERE NOT EXISTS (SELECT 1 FROM gold.dim_user u WHERE u.user_key = f.user_key)
    UNION ALL
    SELECT 1 FROM gold.dim_user_elite e
    WHERE NOT EXISTS (SELECT 1 FROM gold.dim_user u WHERE u.user_key = e.user_key)
    UNION ALL
    SELECT 1 FROM gold.dim_business_category c
    WHERE NOT EXISTS (SELECT 1 FROM gold.dim_business b WHERE b.business_key = c.business_key)
    UNION ALL
    SELECT 1 FROM gold.dim_business_hours h
    WHERE NOT EXISTS (SELECT 1 FROM gold.dim_business b WHERE b.business_key = h.business_key)
    UNION ALL
    SELECT 1 FROM gold.fact_review r
    WHERE NOT EXISTS (SELECT 1 FROM gold.dim_user u WHERE u.user_key = r.user_key)
       OR NOT EXISTS (SELECT 1 FROM gold.dim_business b WHERE b.business_key = r.business_key)
) b;

\echo '>> Test 3C: Orphan (-1) Fallback Rate in fact_review'
\echo '>> Expected Result: Low % (inspect if unusually high)'
SELECT
    COUNT(*) AS total_reviews,
    COUNT(*) FILTER (WHERE user_key = -1) AS orphan_user_reviews,
    ROUND(100.0 * COUNT(*) FILTER (WHERE user_key = -1) / NULLIF(COUNT(*), 0), 4) AS pct_orphan_user,
    COUNT(*) FILTER (WHERE business_key = -1) AS orphan_business_reviews,
    ROUND(100.0 * COUNT(*) FILTER (WHERE business_key = -1) / NULLIF(COUNT(*), 0), 4) AS pct_orphan_business
FROM gold.fact_review;

---

-- 4. Gold Dimensional Business Logic Checks
\echo '>> Test 4A: dim_business_hours Consistency (day_number, times, 24h, duration)'
\echo '>> Expected Result: 0'
SELECT COUNT(*) AS invalid_hours_rows
FROM gold.dim_business_hours
WHERE day_number NOT BETWEEN 1 AND 7
   OR day_of_week IS NULL
   OR open_time IS NULL
   OR close_time IS NULL
   OR open_duration_hours IS NULL
   OR open_duration_hours <= 0
   OR open_duration_hours > 24.0
   OR (is_24h = TRUE AND (open_time <> TIME '00:00' OR close_time <> TIME '00:00' OR open_duration_hours <> 24.0))
   OR (is_24h = FALSE AND closes_next_day <> (close_time < open_time));

\echo '>> Test 4B: dim_user_elite Year Boundary Check'
\echo '>> Expected Result: 0'
SELECT COUNT(*) AS invalid_elite_years
FROM gold.dim_user_elite
WHERE elite_year < 2005 OR elite_year > EXTRACT(YEAR FROM CURRENT_DATE)::INT;

\echo '====================================================='
\echo 'GOLD LAYER DATA QUALITY TESTS COMPLETED'
\echo '====================================================='
