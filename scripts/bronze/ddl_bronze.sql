/* 
=====================================================
 Bronze Layer tables creation
=====================================================

 PURPOSE
 This script creates tables in the Bronze layer.

 -WHAT THIS SCRIPT DOES

 Creates 3 Bronze tables (if they do not exist):
    - bronze.yelp_business
    - bronze.yelp_review
    - bronze.yelp_user

    Each table contains:
      - id (BIGSERIAL primary key)
      - raw_json (JSONB, raw record)
      - ingested_at (timestamp of ingestion)

 -REQUIREMENTS
    -init.sql script must be run previously

 =====================================================
*/



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
