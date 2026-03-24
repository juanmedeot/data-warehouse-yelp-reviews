-- =====================================================
-- BRONZE LAYER INGESTION SCRIPT (YELP DATASET)
-- =====================================================
--
-- PURPOSE
-- This script creates raw ingestion tables in the Bronze layer
-- and loads Yelp NDJSON datasets (business, review, user) into
-- PostgreSQL as JSONB.
--
-- Each row in the source files is a JSON object (NDJSON format),
-- and is stored as-is in a single JSONB column (`raw_json`).
--
-- -----------------------------------------------------
-- WHAT THIS SCRIPT DOES
--
-- 1. Creates 3 Bronze tables (if they do not exist):
--    - bronze.yelp_business
--    - bronze.yelp_review
--    - bronze.yelp_user
--
--    Each table contains:
--      - id (BIGSERIAL primary key)
--      - raw_json (JSONB, raw record)
--      - ingested_at (timestamp of ingestion)
--
-- 2. Disables synchronous_commit:
--    - Improves bulk load performance
--    - Safe for batch ingestion (may risk minimal data loss if crash occurs)
--
-- 3. Loads data using \copy (psql meta-command):
--    - Reads local files (client-side)
--    - Required when files are not accessible by the DB server
--
-- 4. Uses a CSV "parsing bypass" technique:
--    - FORMAT csv
--    - DELIMITER, QUOTE, ESCAPE set to non-existing control characters
--
--    This ensures:
--      ✔ Each line is treated as a single field
--      ✔ JSON is not broken by commas or quotes
--      ✔ Reliable ingestion of NDJSON files into JSONB
--
-- -----------------------------------------------------
-- REQUIRED VARIABLES
--
-- This script expects psql variables:
--
--   DATA_PATH     → directory containing dataset files
--   BUSINESS_FILE → business dataset filename
--   REVIEW_FILE   → review dataset filename
--   USER_FILE     → user dataset filename
--
-- Example:
--   \set DATA_PATH 'C:/data/yelp'
--   \set BUSINESS_FILE 'yelp_academic_dataset_business.json'
--   \set REVIEW_FILE   'yelp_academic_dataset_review.json'
--   \set USER_FILE     'yelp_academic_dataset_user.json'
--
-- -----------------------------------------------------
-- This script MUST be executed using psql (not DBeaver or GUI tools),
-- because it uses the \copy meta-command.
--
-- Option 1 — From terminal (recommended):
--
--   psql -U <user> -d datawarehouse \
--     -v DATA_PATH="'C:/data/yelp'" \
--     -v BUSINESS_FILE="'yelp_academic_dataset_business.json'" \
--     -v REVIEW_FILE="'yelp_academic_dataset_review.json'" \
--     -v USER_FILE="'yelp_academic_dataset_user.json'" \
--     -f bronze_load.sql
--
-- Option 2 — Inside psql:
--
--   \set DATA_PATH 'C:/data/yelp'
--   \set BUSINESS_FILE 'yelp_academic_dataset_business.json'
--   \set REVIEW_FILE   'yelp_academic_dataset_review.json'
--   \set USER_FILE     'yelp_academic_dataset_user.json'
--
--   \i path/to/bronze_load.sql
--
-- -----------------------------------------------------
-- NOTES
--
-- - Source files must be in NDJSON format (one JSON per line)
-- - Files must be UTF-8 encoded
-- - This script does NOT perform validation or transformation
-- - Raw data is stored as-is (Bronze layer philosophy)
--
-- -----------------------------------------------------
-- NEXT STEPS
--
-- After ingestion:
--   - Validate row counts vs source files
--   - Transform data into structured tables (Silver layer)
--   - Extract nested JSON fields into columns
--
-- =====================================================



CREATE TABLE IF NOT EXISTS bronze.yelp_business (
    id BIGSERIAL PRIMARY KEY,
    raw_json JSONB NOT NULL,
    ingested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS bronze.yelp_review (
    id BIGSERIAL PRIMARY KEY,
    raw_json JSONB NOT NULL,
    ingested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS bronze.yelp_user (
    id BIGSERIAL PRIMARY KEY,
    raw_json JSONB NOT NULL,
    ingested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

SET synchronous_commit = OFF;

\copy bronze.yelp_business(raw_json)
FROM :'DATA_PATH'/'BUSINESS_FILE'
WITH (FORMAT csv,
    DELIMITER E'\x01', 
    QUOTE E'\x02', 
    ESCAPE E'\x03', 
    ENCODING 'UTF8'
);

\copy bronze.yelp_review(raw_json)
FROM :'DATA_PATH'/'REVIEW_FILE'
WITH (FORMAT csv,
    DELIMITER E'\x01', 
    QUOTE E'\x02', 
    ESCAPE E'\x03', 
    ENCODING 'UTF8'
);

\copy bronze.yelp_user(raw_json)
FROM :'DATA_PATH'/'USER_FILE'
WITH (FORMAT csv,
    DELIMITER E'\x01', 
    QUOTE E'\x02', 
    ESCAPE E'\x03', 
    ENCODING 'UTF8'
);
