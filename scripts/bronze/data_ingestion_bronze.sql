/* 
=====================================================
Bronze Layer Ingestion Script
=====================================================

 PURPOSE
 This script creates raw ingestion tables in the Bronze layer
 and loads Yelp NDJSON datasets (business, review, user) into
 PostgreSQL as JSONB.

 Each row in the source files is a JSON object (NDJSON format),
 and is stored as-is in a single JSONB column (`raw_json`).

 -WHAT THIS SCRIPT DOES

 1. Disables synchronous_commit:
    - Improves bulk load performance
    - Safe for batch ingestion (may risk minimal data loss if crash occurs)

 2. Loads data using \copy (psql meta-command):
    - Reads local files (client-side)
    - Required when files are not accessible by the DB server

 3. Uses a CSV "parsing bypass" technique:
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
 This script MUST be executed using psql (not DBeaver or GUI tools),
 because it uses the \copy meta-command.

 Option 1 — From terminal (recommended):

   psql -U <user> -d datawarehouse \
     -v DATA_PATH="'files_path'" \
     -v BUSINESS_FILE="'yelp_academic_dataset_business.json'" \
     -v REVIEW_FILE="'yelp_academic_dataset_review.json'" \
     -v USER_FILE="'yelp_academic_dataset_user.json'" \
     -f data_ingestion_bronze.sql

 Option 2 — Inside psql:

   \set DATA_PATH 'files_path'
   \set BUSINESS_FILE 'yelp_academic_dataset_business.json'
   \set REVIEW_FILE   'yelp_academic_dataset_review.json'
   \set USER_FILE     'yelp_academic_dataset_user.json'

   \i path/to/data_ingestion_bronze.sql

 Check tests folder for data validation
 =====================================================
*/


SET synchronous_commit = OFF;

TRUNCATE TABLE bronze.yelp_business;
\copy bronze.yelp_business(raw_json) FROM <BUSINESS_FILE> WITH (FORMAT csv, DELIMITER E'\x01', QUOTE E'\x02', ESCAPE E'\x03', ENCODING 'UTF8');

TRUNCATE TABLE bronze.yelp_review;
\copy bronze.yelp_review(raw_json) FROM <REVIEW_FILE> WITH (FORMAT csv, DELIMITER E'\x01', QUOTE E'\x02', ESCAPE E'\x03', ENCODING 'UTF8');

TRUNCATE TABLE bronze.yelp_user;
\copy bronze.yelp_user(raw_json) FROM <USER_FILE> WITH (FORMAT csv, DELIMITER E'\x01', QUOTE E'\x02', ESCAPE E'\x03', ENCODING 'UTF8');
