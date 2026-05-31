/*
===============================================================================
Data Quality Checks - Silver Layer (yelp_business)
===============================================================================
Script Purpose: 
    This script performs several data quality checks on the silver.yelp_business 
    table to ensure data integrity, consistency, and accuracy after the 
    ingestion process from the bronze layer.

Checks performed:
    1. Row count comparison between Bronze and Silver layers.
    2. Primary Key (business_id) uniqueness and nullity.
    3. Completeness (Missing/Null values) across all critical columns.
    4. Geolocation boundaries (Latitude/Longitude).
    5. Business logic consistency (Stars ratings and Review counts).
    6. Binary consistency (is_open status).

How to run:
 This script uses psql meta-command (\echo).

 From terminal:

   psql -h <host> -U <user> -d datawarehouse -f "path\silver_yelp_business_test.sql"

===============================================================================
*/

\echo '====================================================='
\echo 'STARTING DATA QUALITY TESTS: silver.yelp_business'
\echo '====================================================='

-- 1. Row Count Comparison
-- Expected Result: 0
\echo '>> Test 1: Bronze vs Silver row count difference'
\echo '>>Expected Result: 0'
SELECT COUNT(*) - (SELECT COUNT(*) FROM bronze.yelp_business) AS bronze_silver_difference 
FROM silver.yelp_business;

-- 2. Business_id Duplicates
-- Expected Result: No rows
\echo '>> Test 2: Checking for duplicates in business_id'
\echo '>>Expected Result: 0 rows'
SELECT business_id, COUNT(*) 
FROM silver.yelp_business 
GROUP BY business_id 
HAVING COUNT(*) > 1;

-- 3. Completeness & Null Handling
-- Expected Result: 0 (since we handled N/A and NULL in ingestion)
\echo '>> Test 3: Counting missing or null values in critical fields'
\echo '>>Expected Result: 0'
SELECT COUNT(*) AS total_missing_values
FROM silver.yelp_business 
WHERE 
	business_id IS NULL OR
	name IS NULL OR name = 'null' OR name = '' OR 
	address IS NULL OR address = 'null' OR address = '' OR  
	city IS NULL OR city = 'null' OR city = '' OR 
	state IS NULL OR state = 'null' OR state = '' OR 
	postal_code IS NULL OR postal_code = 'null' OR postal_code = '' OR 
	latitude IS NULL OR
	longitude IS NULL OR 
	stars IS NULL OR 
	review_count IS NULL OR
	is_open IS NULL OR 
	attributes = 'null' OR 
	categories IS NULL OR categories = 'null' OR categories = '' OR 
	hours = 'null' OR
	ingested_at IS NULL;

-- 4. Geolocation Boundaries
-- Expected Result: No rows
\echo '>> Test 4: Checking latitude (-90 to 90) and longitude (-180 to 180) boundaries'
\echo '>>Expected Result: 0 rows'
SELECT business_id, latitude, longitude 
FROM silver.yelp_business
WHERE 
	latitude < -90 OR 
	latitude > 90 OR 
	longitude < -180 OR 
	longitude > 180;

-- 5. Stars Consistency
-- Expected Result: No rows (Checks range 1-5 and 0.5 increments)
\echo '>> Test 5: Checking stars range (1-5) and 0.5 increments'
\echo '>>Expected Result: 0 rows'
SELECT business_id, stars 
FROM silver.yelp_business 
WHERE 
	stars < 1 OR 
	stars > 5 OR 
	(stars % 0.5) <> 0;

-- 6. Review Count Boundaries
-- Expected Result: No rows
\echo '>> Test 6: Checking for negative review_counts'
\echo '>>Expected Result: 0 rows'
SELECT business_id, review_count 
FROM silver.yelp_business 
WHERE review_count < 0;

-- 7. Is_Open Consistency
-- Expected Result: No rows (Should only be 0 or 1)
\echo '>> Test 7: Checking is_open valid values (0 or 1)'
\echo '>>Expected Result: 0 rows'
SELECT business_id, is_open 
FROM silver.yelp_business 
WHERE 
	is_open < 0 OR 
	is_open > 1;

\echo '====================================================='
\echo 'DATA QUALITY TESTS COMPLETED'
\echo '====================================================='
