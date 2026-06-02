/*
===============================================================================
Data Quality Checks - Silver Layer (yelp_review)
===============================================================================
Script Purpose: 
    This script performs several data quality checks on the silver.yelp_review 
    table to ensure data integrity, consistency, and accuracy after the 
    ingestion process from the bronze layer.

Checks performed:
    1. Row count comparison between Bronze and Silver layers.
    2. Primary Key (review_id) uniqueness.
    3. Referential integrity validation (percentage of orphan user_id and business_id).
    4. Completeness (Missing/Null values) across all columns.
    5. Unwanted leading/trailing spaces detection in text and key fields.
    6. Business logic consistency (Integer star ratings between 1 and 5).
    7. Chronological boundaries for review dates (post-Yelp foundation).
    8. Metric boundaries (Non-negative values for useful, funny, and cool).

How to run:
 This script uses psql meta-command (\echo).

 From terminal:
 psql -h <host> -U <user> -d datawarehouse -f "path\silver_yelp_review_test.sql"

===============================================================================
*/

\echo '====================================================='
\echo 'STARTING DATA QUALITY TESTS: silver.yelp_review'
\echo '====================================================='

--Check bronze and silver # of rows
--Expected result: 0
\echo '>> Test 1: Row count difference (Bronze vs Silver)'
\echo '>> Expected Result: 0'
select count(*)-(select count(*) from bronze.yelp_review) AS bronze_silver_difference from silver.yelp_review


--Check duplicates review_id
--Expected result: 0 rows
\echo '>> Test 2: Duplicate review_id count'
\echo '>> Expected Result: 0 rows'
select count(*) from silver.yelp_review group by review_id having count(*) > 1


--Check if user_id exists in yelp_user table
--Expected result: < 0.01% of total row count
\echo '>> Test 3: Percentage of orphan reviews by user_id'
\echo '>> Expected Result: < 0.01%'
select round(100.0*count(*)/(select count(*) from silver.yelp_review),4) as perc_total_rows
from silver.yelp_review r left join silver.yelp_user u on r.user_id=u.user_id where u.user_id is null

--Check if business_id exists in yelp_business table
--Expected result: < 0.01% of total row count
\echo '>> Test 4: Percentage of orphan reviews by business_id'
\echo '>> Expected Result: < 0.01%'
select round(100.0*count(*)/(select count(*) from silver.yelp_review),4) as perc_total_rows
from silver.yelp_review r left join silver.yelp_business b on r.business_id=b.business_id where b.business_id is null


--Check null values and completeness
--Expected result: 0 rows
\echo '>> Test 5: Missing and Null values count (All columns)'
\echo '>> Expected Result: 0 rows'
SELECT COUNT(*) AS total_missing_values
FROM silver.yelp_review 
WHERE 
	review_id IS NULL OR review_id = 'null' OR review_id = '' OR
	user_id IS NULL OR user_id = 'null' OR user_id = '' or
	business_id IS NULL OR business_id = 'null' OR business_id = '' or
	stars IS NULL OR 
	date IS NULL OR
	text IS NULL OR text = 'null' OR text = '' OR 
	useful IS NULL or
	funny IS NULL or
	cool IS NULL OR
	ingested_at IS NULL;

--Check unwanted spaces (pk and foreing keys)
--Expected result: 0 rows
\echo '>> Test 6: Unwanted leading/trailing spaces'
\echo '>> Expected Result: 0 rows'
SELECT COUNT(*) AS spaces_rows
FROM silver.yelp_review 
WHERE 
	trim(review_id) <> review_id or
	trim(user_id) <> user_id or
	trim(business_id) <> business_id or
	trim(text) <> text;


--Check consistency and boundries in stars field
--Expected result: 0 rows
\echo '>> Test 7: Review stars boundaries'
\echo '>> Expected Result: 0 rows'
SELECT stars 
FROM silver.yelp_review 
WHERE 
    stars < 1 OR 
    stars > 5 OR 
	(stars % 1.0) <> 0;

--Check boundries in date field
--Expected result: 0 rows
\echo '>> Test 8: Date logical boundaries (Post-Yelp foundation to present)'
\echo '>> Expected Result: 0 rows'
SELECT COUNT(*)
FROM silver.yelp_review 
where date < '2004-10-01' or date > CURRENT_DATE

--Check consistency and boundries in useful, funny and cool fields
--Expected result: 0 rows
\echo '>> Test 9: Negative values check in engagement metrics'
\echo '>> Expected Result: 0 rows'
SELECT COUNT(*)
FROM silver.yelp_review 
where 
	useful < 0 or
	funny < 0 or
	cool < 0;
	
\echo '====================================================='
\echo 'DATA QUALITY TESTS COMPLETED'
\echo '====================================================='
