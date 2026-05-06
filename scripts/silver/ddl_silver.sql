/* 
=====================================================
 Silver Layer tables creation
=====================================================

 PURPOSE
 This script creates tables in the Silver layer.

 -WHAT THIS SCRIPT DOES

 Creates 3 Silver tables (if they do not exist):
    - silver.yelp_business
    - silver.yelp_review
    - silver.yelp_user


 -REQUIREMENTS
    -init.sql script must be run previously

 =====================================================
*/



CREATE TABLE IF NOT EXISTS silver.yelp_business (
    business_id VARCHAR(22) PRIMARY KEY,
    name VARCHAR(255),
    address VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(2),
    postal_code VARCHAR(20),
    latitude NUMERIC(9,6),
    longitude NUMERIC(9,6),
    stars NUMERIC(3,1),
    review_count INTEGER,
    is_open INTEGER,
    attributes JSONB,
    categories TEXT,
    hours JSONB,
    ingested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS silver.yelp_review (
    review_id VARCHAR(22) PRIMARY KEY,
    user_id VARCHAR(22),
    business_id VARCHAR(22),
    stars INTEGER,
    date DATE,
    text TEXT,
    useful INTEGER,
    funny INTEGER,
    cool INTEGER,
    ingested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS silver.yelp_user (
    user_id VARCHAR(22) PRIMARY KEY,
    name VARCHAR(255),
    review_count INTEGER,
    yelping_since DATE,
    friends JSONB,
    useful INTEGER,
    funny INTEGER,
    cool INTEGER,
    fans INTEGER,
    elite JSONB,
    average_stars NUMERIC(3,2),
    compliment_hot INTEGER,
    compliment_more INTEGER,
    compliment_profile INTEGER,
    compliment_cute INTEGER,
    compliment_list INTEGER,
    compliment_note INTEGER,
    compliment_plain INTEGER,
    compliment_cool INTEGER,
    compliment_funny INTEGER,
    compliment_writer INTEGER,
    compliment_photos INTEGER,
    ingested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
