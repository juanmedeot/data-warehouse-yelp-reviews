/* 
=====================================================
Gold Layer Transformation & Loading Script
=====================================================

PURPOSE
This script performs the transformation from the Silver layer 
to the Gold layer in the Yelp Data Warehouse.

It structures the cleaned data into an optimized Snowflake schema 
using Materialized Views, incorporating surrogate keys, dimensional 
hierarchies, and robust handling for complex JSON, 
business hours, and referential integrity.

WARNING: This script drops and recreates all gold layer materialized views 
to ensure a fully refreshed analytical state.

- WHAT THIS SCRIPT DOES

1. Snowflake Schema Modeling:
   - Builds normalized dimensional tables (business, user, friends, elite, categories, hours) and fact tables (reviews).
   - Implements surrogate keys (`business_key`, `user_key`, `review_key`) to power high-performance BI reporting.

2. Complex Data Parsing & Anomaly Handling:
   - Flattens JSONB fields (hours) and comma-separated string arrays (categories, friends, elite).
   - Resolves business hours edge cases, distinguishing true 24/7 operations from isolated closed/rest days (`0:0-0:0`).
   - Calculates midnight-crossing shifts (`closes_next_day`).

3. Referential Integrity & Default Fallbacks:
   - Assigns default `-1` surrogate keys (UNKNOWN) to orphan references in fact tables using `COALESCE`, preventing broken joins.

- HOW TO RUN
This script uses psql meta-commands (\echo, \gset).

From terminal:

   psql -h <host> -U <user> -d datawarehouse -f "path\data_ingestion_gold.sql"

=====================================================
*/

\set ON_ERROR_STOP on
BEGIN;

SELECT clock_timestamp() AS start_time_batch \gset
\echo '====================================================='
\echo 'Loading data into Gold Layer'
\echo '====================================================='

\echo '>> Disabling Synchronous Commit'
SET synchronous_commit = OFF;

\echo '-----------------------------------------------------'
 
/*
===============================================================================
Materialized View: gold.dim_user
===============================================================================
Script Purpose:
    Creates the user dimension for the Gold Layer (Snowflake Schema).
    It generates a numeric surrogate key (user_key) and includes an 
    Unknown Member (-1) row to handle orphan records from the fact table.

Dependencies:
- silver.yelp_user
===============================================================================
*/

SELECT clock_timestamp() AS start_time_user \gset
\echo '>> Droping table materialized view gold.dim_user'

DROP MATERIALIZED VIEW IF EXISTS gold.dim_user CASCADE;

\echo '>> Loading data into gold.dim_user'

CREATE MATERIALIZED VIEW gold.dim_user as
SELECT 
    -1 AS user_key,
    'UNKNOWN' AS user_id,
    'UNKNOWN USER' AS name,
    NULL::DATE AS yelping_since,
    0 AS review_count,
    0.00::NUMERIC(3, 2) AS average_stars,
    0 AS useful,
    0 AS funny,
    0 AS cool,
    0 AS fans,
    0 AS compliment_hot, 
    0 AS compliment_more, 
    0 AS compliment_profile, 
    0 AS compliment_cute, 
    0 AS compliment_list, 
    0 AS compliment_note, 
    0 AS compliment_plain, 
    0 AS compliment_cool, 
    0 AS compliment_funny, 
    0 AS compliment_writer, 
    0 AS compliment_photos
    
UNION ALL

SELECT 
    ROW_NUMBER() OVER (ORDER BY user_id) AS user_key,
    user_id,
    name,
    yelping_since,
    review_count,
    average_stars,
    useful,
    funny,
    cool,
    fans,
    compliment_hot, 
    compliment_more, 
    compliment_profile, 
    compliment_cute, 
    compliment_list, 
    compliment_note, 
    compliment_plain, 
    compliment_cool, 
    compliment_funny, 
    compliment_writer, 
    compliment_photos
FROM silver.yelp_user;

CREATE UNIQUE INDEX idx_dim_user_key ON gold.dim_user(user_key);
CREATE INDEX idx_dim_user_natural ON gold.dim_user(user_id);

SELECT (clock_timestamp() - :'start_time_user') as diff_user \gset
\echo '>> Load Time:' :diff_user

\echo '-----------------------------------------------------'

/*
===============================================================================
Materialized View: gold.dim_user_friend (Snowflake Sub-dimension)
===============================================================================
Script Purpose:
    Flattens the comma-separated 'friends' JSONB column from silver.yelp_user 
    into a normalized 1-to-many relationship table in the Gold layer.
    Linked to dim_user using the numeric surrogate key (user_key).

Dependencies:
- gold.dim_user
- silver.yelp_user
===============================================================================
*/
SELECT clock_timestamp() AS start_time_user_friend \gset
\echo '>> Droping table materialized view gold.dim_user_friend'

DROP MATERIALIZED VIEW IF EXISTS gold.dim_user_friend CASCADE;

\echo '>> Loading data into gold.dim_user_friend'

CREATE MATERIALIZED VIEW gold.dim_user_friend AS
SELECT DISTINCT 
    u.user_key,
    TRIM(f.raw_friend_id, ' ''"') AS friend_user_id
FROM gold.dim_user u
CROSS JOIN LATERAL (
    SELECT unnest(string_to_array(
        TRIM(b_silver.friends::text, ' ''"'), 
        ','
    )) AS raw_friend_id
    FROM silver.yelp_user b_silver
    WHERE b_silver.user_id = u.user_id
      AND u.user_id <> 'UNKNOWN'
      AND b_silver.friends IS NOT NULL
      AND b_silver.friends::text <> ''
      AND b_silver.friends::text <> 'None'
) f;

CREATE UNIQUE INDEX idx_gold_dim_user_friend_pk ON gold.dim_user_friend (user_key, friend_user_id);
CREATE INDEX idx_gold_dim_user_friend_fid ON gold.dim_user_friend (friend_user_id);

SELECT (clock_timestamp() - :'start_time_user_friend') as diff_user_friend \gset
\echo '>> Load Time:' :diff_user_friend

\echo '-----------------------------------------------------'

/*
===============================================================================
Materialized View: gold.dim_user_elite (Snowflake Sub-dimension)
===============================================================================
Script Purpose:
    Flattens the comma-separated 'elite' years from silver.yelp_user into a 
    normalized 1-to-many table linked via user_key. Includes text cleaning
    and distinct filtering to prevent duplicate key violations.
    
Dependencies:
- gold.dim_user
- silver.yelp_user
===============================================================================
*/
SELECT clock_timestamp() AS start_time_user_elite \gset
\echo '>> Droping table materialized view gold.dim_user_elite'

DROP MATERIALIZED VIEW IF EXISTS gold.dim_user_elite CASCADE;

\echo '>> Loading data into gold.dim_user_elite'

CREATE MATERIALIZED VIEW gold.dim_user_elite AS
SELECT DISTINCT 
    u.user_key,
    TRIM(e.raw_elite_year, ' ''"')::INTEGER AS elite_year
FROM gold.dim_user u
CROSS JOIN LATERAL (
    SELECT unnest(string_to_array(
        TRIM(u_silver.elite::text, ' ''"'), 
        ','
    )) AS raw_elite_year
    FROM silver.yelp_user u_silver
    WHERE u_silver.user_id = u.user_id
        AND u.user_id <> 'UNKNOWN'
        AND u_silver.elite IS NOT NULL
        AND u_silver.elite::text <> ''
        AND u_silver.elite::text <> 'None'
) e;



CREATE UNIQUE INDEX idx_gold_dim_user_elite_pk ON gold.dim_user_elite (user_key, elite_year);
CREATE INDEX idx_gold_dim_user_elite_year ON gold.dim_user_elite (elite_year);

SELECT (clock_timestamp() - :'start_time_user_elite') as diff_user_elite \gset
\echo '>> Load Time:' :diff_user_elite

\echo '-----------------------------------------------------'

/*
===============================================================================
Materialized View: gold.dim_business
===============================================================================
Script Purpose:
    Creates the business dimension for the Gold Layer (Snowflake Schema).
    It generates a numeric surrogate key (business_key) and includes an 
    Unknown Member (-1) row to handle orphan records from the fact table.

Dependencies:
- silver.yelp_business
===============================================================================
*/

SELECT clock_timestamp() AS start_time_business \gset
\echo '>> Droping table materialized view gold.dim_business'

DROP MATERIALIZED VIEW IF EXISTS gold.dim_business CASCADE;

\echo '>> Loading data into gold.dim_business'

CREATE MATERIALIZED VIEW gold.dim_business AS
SELECT 
    -1 AS business_key,
    'UNKNOWN' AS business_id,
    'UNKNOWN BUSINESS' AS name,
    'UNKNOWN' AS address,
    'UNKNOWN' AS city,
    'UNKNOWN' AS state,
    'UNKNOWN' AS postal_code,
    NULL::NUMERIC(10, 7) AS latitude,
    NULL::NUMERIC(10, 7) AS longitude,
    0.0::NUMERIC(2, 1) AS stars,
    0 AS review_count,
    FALSE AS is_open

UNION ALL

SELECT
    ROW_NUMBER() OVER (ORDER BY business_id) AS business_key,
    business_id,
    name,
    address,
    city,
    state,
    postal_code,
    latitude,
    longitude,
    stars,
    review_count,
    is_open::BOOLEAN AS is_open
FROM silver.yelp_business;

CREATE UNIQUE INDEX idx_dim_business_key ON gold.dim_business(business_key);
CREATE INDEX idx_dim_business_natural ON gold.dim_business(business_id);

SELECT (clock_timestamp() - :'start_time_business') as diff_business \gset
\echo '>> Load Time:' :diff_business

\echo '-----------------------------------------------------'

/*
===============================================================================
Materialized View: gold.dim_business_category (Snowflake Sub-dimension)
===============================================================================
Script Purpose:
    Flattens the comma-separated 'categories' column from silver.yelp_business 
    into a normalized 1-to-many relationship table in the Gold layer.
    Linked to dim_business using the numeric surrogate key (business_key).

Dependencies:
- gold.dim_business
- silver.yelp_business
===============================================================================
*/

SELECT clock_timestamp() AS start_business_category \gset
\echo '>> Droping table materialized view gold.dim_business_category'

DROP MATERIALIZED VIEW IF EXISTS gold.dim_business_category CASCADE;

\echo '>> Loading data into gold.dim_business_category'

CREATE MATERIALIZED VIEW gold.dim_business_category AS
SELECT DISTINCT 
    b.business_key,
    TRIM(c.raw_category_name, ' ''"') AS category_name
FROM gold.dim_business b
CROSS JOIN LATERAL (
    SELECT unnest(string_to_array(
        TRIM(b_silver.categories::text, ' ''"'), 
        ','
    )) AS raw_category_name
    FROM silver.yelp_business b_silver
    WHERE b_silver.business_id = b.business_id
        AND b.business_id <> 'UNKNOWN'
        AND b_silver.categories IS NOT NULL
        AND b_silver.categories::text <> ''
        AND b_silver.categories::text <> 'None'
) c;

CREATE UNIQUE INDEX idx_gold_dim_business_cat_pk ON gold.dim_business_category (business_key, category_name);
CREATE INDEX idx_gold_dim_business_cat_name ON gold.dim_business_category (category_name);


SELECT (clock_timestamp() - :'start_business_category') as diff_business_category \gset
\echo '>> Load Time:' :diff_business_category

\echo '-----------------------------------------------------'
   
/*
===============================================================================
Materialized View: gold.dim_business_hours (Snowflake Sub-dimension)
===============================================================================
Script Purpose:
    Flattens the JSONB 'hours' column from silver.yelp_business into a 
    normalized 1-to-many relationship table in the Gold layer.
    Extracts open/close times, handles midnight-crossing schedules, 
    filters out closed days (0:0-0:0), and links to dim_business using 
    the numeric surrogate key (business_key).

Dependencies:
- gold.dim_business
- silver.yelp_business
===============================================================================
*/
SELECT clock_timestamp() AS start_time_business_hours \gset
\echo '>> Droping table materialized view gold.dim_business_hours'

DROP MATERIALIZED VIEW IF EXISTS gold.dim_business_hours CASCADE;

\echo '>> Loading data into gold.dim_business_hours'

CREATE MATERIALIZED VIEW gold.dim_business_hours AS
WITH days AS (
    SELECT
        s.business_id,
        kv.key   AS day_name,
        kv.value AS hours_range,
        (kv.value IN ('0:0-0:0', '0:0-0', '0-0', '0:00-0:00')) AS is_zero_day
    FROM silver.yelp_business s
    CROSS JOIN LATERAL jsonb_each_text(s.hours::jsonb) kv
    WHERE s.hours IS NOT NULL
      AND s.hours::text NOT IN ('', 'None', '{}')
      AND jsonb_typeof(s.hours::jsonb) = 'object'
),
flagged AS (
    SELECT *,
           count(*) FILTER (WHERE is_zero_day) OVER (PARTITION BY business_id) AS zero_days
    FROM days
)
SELECT
    b.business_key,
    CASE f.day_name
        WHEN 'Monday' THEN 1 WHEN 'Tuesday'  THEN 2 WHEN 'Wednesday' THEN 3
        WHEN 'Thursday' THEN 4 WHEN 'Friday' THEN 5 WHEN 'Saturday'  THEN 6
        WHEN 'Sunday'   THEN 7
    END AS day_number,
    f.day_name AS day_of_week,
    t.open_time,
    t.close_time,
    (t.close_time < t.open_time) AS closes_next_day,
    f.is_zero_day AS is_24h,
    CASE
        WHEN f.is_zero_day THEN 24.0
        WHEN t.close_time < t.open_time
             THEN EXTRACT(EPOCH FROM (t.close_time - t.open_time)) / 3600 + 24
        ELSE      EXTRACT(EPOCH FROM (t.close_time - t.open_time)) / 3600
    END::NUMERIC(4, 2) AS open_duration_hours
FROM flagged f
JOIN gold.dim_business b ON b.business_id = f.business_id
CROSS JOIN LATERAL (
    SELECT
        CASE WHEN f.is_zero_day THEN TIME '00:00'
             ELSE split_part(f.hours_range, '-', 1)::TIME END AS open_time,
        CASE WHEN f.is_zero_day THEN TIME '00:00'
             ELSE split_part(f.hours_range, '-', 2)::TIME END AS close_time
) t
--Threshold: 1 day 0:0-0:0 is "24 h" if business has 5 or more; if not, is "closed" (no row)
WHERE NOT f.is_zero_day OR f.zero_days >= 5;

CREATE UNIQUE INDEX idx_gold_dim_business_hours_pk ON gold.dim_business_hours (business_key, day_number);
CREATE INDEX idx_gold_dim_business_hours_day ON gold.dim_business_hours (day_number);

SELECT (clock_timestamp() - :'start_time_business_hours') as diff_business_hours \gset
\echo '>> Load Time:' :diff_business_hours

\echo '-----------------------------------------------------'

/*
===============================================================================
Materialized View: gold.fact_review
===============================================================================
Script Purpose:
    Creates the fact review table for the Gold Layer by joining reviews with 
    user and business dimensions using their surrogate keys.

Dependencies:
- gold.dim_user
- gold.dim_business
- silver.yelp_review
===============================================================================
*/


SELECT clock_timestamp() AS start_time_review \gset
\echo '>> Droping table materialized view gold.fact_review'

DROP MATERIALIZED VIEW IF EXISTS gold.fact_review CASCADE;

\echo '>> Loading data into gold.fact_review'

CREATE MATERIALIZED VIEW gold.fact_review AS
SELECT 
    ROW_NUMBER() OVER (ORDER BY r.review_id) AS review_key,
    r.review_id,
    COALESCE(u.user_key, -1)     AS user_key,
    COALESCE(b.business_key, -1) AS business_key, 
    r.stars,
    r.useful,
    r.funny,
    r.cool,
    r.text,
    r.date::DATE
FROM silver.yelp_review r
LEFT JOIN gold.dim_user u ON r.user_id = u.user_id
LEFT JOIN gold.dim_business b ON r.business_id = b.business_id;

CREATE UNIQUE INDEX idx_fact_review_key ON gold.fact_review(review_key);
CREATE INDEX idx_fact_review_review_id ON gold.fact_review(review_id);
CREATE INDEX idx_fact_review_user_fk ON gold.fact_review(user_key);
CREATE INDEX idx_fact_review_business_fk ON gold.fact_review(business_key);
CREATE INDEX idx_fact_review_date ON gold.fact_review(date);

SELECT (clock_timestamp() - :'start_time_review') as diff_review \gset
\echo '>> Load Time:' :diff_review

COMMIT;

SELECT (clock_timestamp() - :'start_time_batch') as diff_total \gset
\echo '====================================================='
\echo 'Loading data into Gold Layer Completed'
\echo 'Total Load Time:' :diff_total
\echo '====================================================='
