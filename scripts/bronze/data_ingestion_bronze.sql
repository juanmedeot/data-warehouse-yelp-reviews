/* 
=====================================================
Bronze Layer Loading Script
=====================================================

 PURPOSE
 This script creates raw ingestion tables in the Bronze layer
 and loads Yelp NDJSON datasets (business, review, user) into
 PostgreSQL as JSONB.

 Each row in the source files is a JSON object (NDJSON format),
 and is stored as-is in a single JSONB column (`raw_json`).

 WARNING: this script deletes all data in bronze layer tables before ingestions. Run with caution.

 -WHAT THIS SCRIPT DOES

 1. Disables synchronous_commit:
    - Improves bulk load performance
    - Safe for batch ingestion (may risk minimal data loss if crash occurs)

 2. Truncates data form bronze layer tables:
    - Before loading data, deletes all previous data 
    
 3. Loads data using \copy (psql meta-command):
    - Reads local files (client-side)
    - Required when files are not accessible by the DB server

 4. Uses a CSV "parsing bypass" technique:
    - FORMAT csv
    - DELIMITER, QUOTE, ESCAPE set to non-existing control characters

    This ensures:
      ✔ Each line is treated as a single field
      ✔ JSON is not broken by commas or quotes
      ✔ Reliable ingestion of NDJSON files into JSONB

 -REQUIRED VARIABLES

 Replace in the SQL script:

   BUSINESS_FILE → business dataset local directory
   REVIEW_FILE   → review dataset local directory
   USER_FILE     → user dataset local directory


-HOW TO RUN
 This script MUST be executed using psql (not GUI tools),
 because it uses the \copy meta-command.

 From terminal:

   psql -h <host> -U <user> -d datawarehouse -f "path\data_ingestion_bronze.sql"

 =====================================================
*/
\set ON_ERROR_STOP on
BEGIN;

SELECT clock_timestamp() AS start_time_batch \gset
\echo '====================================================='
\echo 'Loading data into Bronze Layer Tables'
\echo '====================================================='

\echo '>> Disabling Synchronous Commit'
SET synchronous_commit = OFF;

\echo '-----------------------------------------------------'
 
SELECT clock_timestamp() AS start_time_business \gset
\echo '>> Truncating table bronze.yelp_business'
TRUNCATE TABLE bronze.yelp_business;

\echo '>> Copying data into bronze.yelp_business table'
\copy bronze.yelp_business(raw_json) FROM <BUSINESS_FILE> WITH (FORMAT csv, DELIMITER E'\x01', QUOTE E'\x02', ESCAPE E'\x03', ENCODING 'UTF8');
SELECT (clock_timestamp() - :'start_time_business') as diff_business \gset
\echo '>> Load Time:' :diff_business

\echo '-----------------------------------------------------'
 
SELECT clock_timestamp() AS start_time_review \gset
\echo '>> Truncating table bronze.yelp_review'
TRUNCATE TABLE bronze.yelp_review;

\echo '>> Copying data into bronze.yelp_review table'
\copy bronze.yelp_review(raw_json) FROM <REVIEW_FILE> WITH (FORMAT csv, DELIMITER E'\x01', QUOTE E'\x02', ESCAPE E'\x03', ENCODING 'UTF8');
SELECT (clock_timestamp() - :'start_time_review') as diff_review \gset
\echo '>> Load Time:' :diff_review

\echo '-----------------------------------------------------'

SELECT clock_timestamp() AS start_time_user \gset
\echo '>> Truncating table bronze.yelp_user'
TRUNCATE TABLE bronze.yelp_user;

\echo '>> Copying data into bronze.yelp_user table'
\copy bronze.yelp_user(raw_json) FROM <USER_FILE> WITH (FORMAT csv, DELIMITER E'\x01', QUOTE E'\x02', ESCAPE E'\x03', ENCODING 'UTF8');
SELECT (clock_timestamp() - :'start_time_user') as diff_user \gset
\echo '>> Load Time:' :diff_user
COMMIT;
 
SELECT (clock_timestamp() - :'start_time_batch') as diff_total \gset
\echo '====================================================='
\echo 'Loading data into Bronze Layer Tables Completed'
\echo 'Total Load Time:' :diff_total
\echo '====================================================='
