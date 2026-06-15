
/* 
=====================================================
Silver Layer Transformation & Loading Script
=====================================================

 PURPOSE
 This script performs the ETL (Extract, Transform, Load) process 
 from the Bronze layer to the Silver layer.
 
 It parses raw JSON data into typed SQL columns, ensuring data 
 integrity and preparing the datasets for analytical use.

 WARNING: This script truncates all silver layer tables before ingestion. 

- WHAT THIS SCRIPT DOES

 1. Disables synchronous_commit:
    - Optimizes performance for internal data movement.
    - Safe for batch processing between database schemas.

 2. Error Handling (\set ON_ERROR_STOP, BEGIN/COMMIT):
    - Ensures the entire batch is treated as a single transaction.
    - If a transformation fails, the script stops and rolls back 
      changes to maintain data consistency.

 3. JSONB Parsing & Type Casting:
    - Extracts keys from `raw_json` using JSONB operators (`->>` for text, `->` for objects/arrays).
    - Converts data to appropriate SQL types: DATE, INTEGER, NUMERIC, and JSONB.
    - Specifically handles coordinate precision (9,6) and star ratings.

 4. Data Cleansing (Deduplication):
    - Uses `ON CONFLICT (id) DO NOTHING` as a safety measure.
    - Ensures that any duplicated business_id, review_id, or user_id 
      coming from the source is filtered out during ingestion.

- HOW TO RUN
 This script uses psql meta-commands (\echo, \gset).

 From terminal:

   psql -h <host> -U <user> -d datawarehouse -f "path\silver_data_ingestion.sql"

 =====================================================
*/

\set ON_ERROR_STOP on
BEGIN;

SELECT clock_timestamp() AS start_time_batch \gset
\echo '====================================================='
\echo 'Loading data into Silver Layer'
\echo '====================================================='

\echo '>> Disabling Synchronous Commit'
SET synchronous_commit = OFF;

\echo '-----------------------------------------------------'
 
SELECT clock_timestamp() AS start_time_business \gset
\echo '>> Truncating table silver.yelp_business'

TRUNCATE TABLE silver.yelp_business;

\echo '>> Loading data into silver.yelp_business'

INSERT INTO silver.yelp_business (
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
    is_open,
    attributes,
    categories,
    hours
)
SELECT 
    raw_json ->> 'business_id',
    COALESCE(NULLIF(NULLIF(TRIM(raw_json ->> 'name'),''),'null'),'N/A'),
    COALESCE(NULLIF(NULLIF(TRIM(raw_json ->> 'address'),''),'null'),'N/A'),
    COALESCE(NULLIF(NULLIF(TRIM(raw_json ->> 'city'),''),'null'),'N/A'),
    COALESCE(NULLIF(NULLIF(TRIM(raw_json ->> 'state'),''),'null'),'N/A'),
    COALESCE(NULLIF(NULLIF(TRIM(raw_json ->> 'postal_code'),''),'null'),'N/A'),
    (raw_json ->> 'latitude')::NUMERIC(9,6),
    (raw_json ->> 'longitude')::NUMERIC(9,6),
    (raw_json ->> 'stars')::NUMERIC(3,1),
    (raw_json ->> 'review_count')::INTEGER,
    (raw_json ->> 'is_open')::INTEGER,
    raw_json -> 'attributes',
    raw_json ->> 'categories',
    raw_json -> 'hours'
FROM bronze.yelp_business;

SELECT (clock_timestamp() - :'start_time_business') as diff_business \gset
\echo '>> Load Time:' :diff_business

\echo '-----------------------------------------------------'

SELECT clock_timestamp() AS start_time_review \gset
\echo '>> Truncating table silver.yelp_review'

TRUNCATE TABLE silver.yelp_review;

\echo '>> Loading data into silver.yelp_review'

INSERT INTO silver.yelp_review (
    review_id, user_id, business_id, stars, date, text, useful, funny, cool
)
SELECT 
    raw_json ->> 'review_id',
    raw_json ->> 'user_id',
    raw_json ->> 'business_id',
    (raw_json ->> 'stars'):::NUMERIC::INTEGER,
    (raw_json ->> 'date')::DATE,
    raw_json ->> 'text',
    CASE WHEN (raw_json ->> 'useful')::INTEGER < 0 THEN 0 ELSE (raw_json ->> 'useful')::INTEGER END AS useful,
    CASE WHEN (raw_json ->> 'funny')::INTEGER < 0 THEN 0 ELSE (raw_json ->> 'funny')::INTEGER END AS funny,
    CASE WHEN (raw_json ->> 'cool')::INTEGER < 0 THEN 0 ELSE (raw_json ->> 'cool')::INTEGER END AS cool
FROM bronze.yelp_review;

SELECT (clock_timestamp() - :'start_time_review') as diff_review \gset
\echo '>> Load Time:' :diff_review

\echo '-----------------------------------------------------'

SELECT clock_timestamp() AS start_time_user \gset
\echo '>> Truncating table silver.yelp_user'

TRUNCATE TABLE silver.yelp_user;

\echo '>> Loading data into silver.yelp_user table'
INSERT INTO silver.yelp_user (
    user_id, name, review_count, yelping_since, friends, useful, funny, cool, 
    fans, elite, average_stars, compliment_hot, compliment_more, 
    compliment_profile, compliment_cute, compliment_list, compliment_note, 
    compliment_plain, compliment_cool, compliment_funny, compliment_writer, 
    compliment_photos
)
SELECT 
    raw_json ->> 'user_id',
    COALESCE(NULLIF(NULLIF(TRIM(raw_json ->> 'name'), ''), 'null'), 'N/A') AS name,
    CASE WHEN (raw_json ->> 'review_count')::INTEGER < 0 THEN NULL ELSE (raw_json ->> 'review_count')::INTEGER END AS review_count,
    (raw_json ->> 'yelping_since')::DATE,
    raw_json -> 'friends', -- Se mantiene como objeto JSONB
    CASE WHEN (raw_json ->> 'useful')::INTEGER < 0 THEN NULL ELSE (raw_json ->> 'useful')::INTEGER END AS useful,
    CASE WHEN (raw_json ->> 'funny')::INTEGER < 0 THEN NULL ELSE (raw_json ->> 'funny')::INTEGER END AS funny,
    CASE WHEN (raw_json ->> 'cool')::INTEGER < 0 THEN NULL ELSE (raw_json ->> 'cool')::INTEGER END AS cool,
    CASE WHEN (raw_json ->> 'fans')::INTEGER < 0 THEN NULL ELSE (raw_json ->> 'fans')::INTEGER END AS fans,
    raw_json -> 'elite', -- Se mantiene como objeto JSONB
    CASE WHEN (raw_json ->> 'average_stars')::NUMERIC(3,2) < 1.00 OR (raw_json ->> 'average_stars')::NUMERIC(3,2) > 5.00 THEN NULL ELSE (raw_json ->> 'average_stars')::NUMERIC(3,2) END AS average_stars,
    CASE WHEN (raw_json ->> 'compliment_hot')::INTEGER < 0 THEN NULL ELSE (raw_json ->> 'compliment_hot')::INTEGER END AS compliment_hot,
    CASE WHEN (raw_json ->> 'compliment_more')::INTEGER < 0 THEN NULL ELSE (raw_json ->> 'compliment_more')::INTEGER END AS compliment_more,
    CASE WHEN (raw_json ->> 'compliment_profile')::INTEGER < 0 THEN NULL ELSE (raw_json ->> 'compliment_profile')::INTEGER END AS compliment_profile,
    CASE WHEN (raw_json ->> 'compliment_cute')::INTEGER < 0 THEN NULL ELSE (raw_json ->> 'compliment_cute')::INTEGER END AS compliment_cute,
    CASE WHEN (raw_json ->> 'compliment_list')::INTEGER < 0 THEN NULL ELSE (raw_json ->> 'compliment_list')::INTEGER END AS compliment_list,
    CASE WHEN (raw_json ->> 'compliment_note')::INTEGER < 0 THEN NULL ELSE (raw_json ->> 'compliment_note')::INTEGER END AS compliment_note,
    CASE WHEN (raw_json ->> 'compliment_plain')::INTEGER < 0 THEN NULL ELSE (raw_json ->> 'compliment_plain')::INTEGER END AS compliment_plain,
    CASE WHEN (raw_json ->> 'compliment_cool')::INTEGER < 0 THEN NULL ELSE (raw_json ->> 'compliment_cool')::INTEGER END AS compliment_cool,
    CASE WHEN (raw_json ->> 'compliment_funny')::INTEGER < 0 THEN NULL ELSE (raw_json ->> 'compliment_funny')::INTEGER END AS compliment_funny,
    CASE WHEN (raw_json ->> 'compliment_writer')::INTEGER < 0 THEN NULL ELSE (raw_json ->> 'compliment_writer')::INTEGER END AS compliment_writer,
    CASE WHEN (raw_json ->> 'compliment_photos')::INTEGER < 0 THEN NULL ELSE (raw_json ->> 'compliment_photos')::INTEGER END AS compliment_photos
FROM bronze.yelp_user;

SELECT (clock_timestamp() - :'start_time_user') as diff_user \gset
\echo '>> Load Time:' :diff_user

COMMIT;

SELECT (clock_timestamp() - :'start_time_batch') as diff_total \gset
\echo '====================================================='
\echo 'Loading data into Silver Layer Completed'
\echo 'Total Load Time:' :diff_total
\echo '====================================================='
