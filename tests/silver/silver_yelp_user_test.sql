/*
===============================================================================
Data Quality Checks - Silver Layer (yelp_user)
===============================================================================
Script Purpose: 
    This script performs several data quality checks on the silver.yelp_user 
    table to ensure data integrity, consistency, and accuracy after the 
    ingestion process from the bronze layer.

Checks performed:
    1. Row count comparison between Bronze and Silver layers.
    2. Primary Key (user_id) uniqueness.
    3. Completeness (Missing/Null values and JSONB parsing leaks for critical fields).
    4. Metric reliability (Percentage of NULL values across numeric metric fields).
    5. Metric boundaries (Non-negative values for review counts, useful, fans, compliments, etc.).
    6. Unwanted leading/trailing spaces detection in text and key fields.
    7. Chronological boundaries for user registration dates (post-Yelp foundation).
    8. Business logic consistency (Decimal average_stars ratings between 1.00 and 5.00).

How to run:
 This script uses psql meta-command (\echo).

 From terminal:
 psql -h <host> -U <user> -d datawarehouse -f "path\silver_yelp_user_test.sql"

===============================================================================
*/


\echo '====================================================='
\echo 'STARTING DATA QUALITY TESTS: silver.yelp_user'
\echo '====================================================='

-- 1. Check bronze and silver # of rows
-- Identifica si hubo pérdida de registros durante la migración o la ingesta.
\echo '>> Test 1: Row Count Comparison (Bronze vs Silver)'
\echo '>> Expected Result: 0'
SELECT COUNT(*) - (SELECT COUNT(*) FROM bronze.yelp_user) AS bronze_silver_difference 
FROM silver.yelp_user;

---

-- 2. Check duplicates in user_id field
-- Garantiza la unicidad de la Clave Primaria lógica del negocio.
\echo '>> Test 2: Duplicate check on user_id'
\echo '>> Expected Result: 0'
SELECT COUNT(*) AS duplicate_users_count
FROM (
    SELECT user_id 
    FROM silver.yelp_user 
    GROUP BY user_id 
    HAVING COUNT(*) > 1
) AS dupes;

---

-- 3A. Check missing values and JSONB leaks (Critical)
-- Valida que campos mandatorios no sean nulos ni contengan strings residuales "sucios".
\echo '>> Test 3A: Critical Missing Values and JSONB Leaks'
\echo '>> Expected Result: 0'
SELECT COUNT(*) AS critical_missing_or_leaks 
FROM silver.yelp_user 
WHERE 
    user_id IS NULL OR user_id = 'null' OR user_id = '' OR
    name IS NULL OR name = 'null' OR name = '' OR
    yelping_since IS NULL OR
    ingested_at IS NULL;

---

-- 3B. Check % of NULL values in metric fields
-- Monitorea el volumen de datos corruptos neutralizados en la transformación.
\echo '>> Test 3B: Percentage of NULL values in Metric Fields'
\echo '>> Expected Result: < 0.1%'
SELECT ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM silver.yelp_user), 4) AS perc_null_metrics
FROM silver.yelp_user 
WHERE
    review_count IS NULL OR
    useful IS NULL OR
    funny IS NULL OR
    cool IS NULL OR
    fans IS NULL OR
    average_stars IS NULL OR
    compliment_hot IS NULL OR
    compliment_more IS NULL OR
    compliment_profile IS NULL OR
    compliment_cute IS NULL OR
    compliment_list IS NULL OR
    compliment_note IS NULL OR
    compliment_plain IS NULL OR
    compliment_cool IS NULL OR
    compliment_funny IS NULL OR
    compliment_writer IS NULL OR
    compliment_photos IS NULL;

---

-- 4. Check boundaries and consistency in metric fields
-- Valida que la lógica defensiva haya atrapado con éxito cualquier número negativo.
\echo '>> Test 4: Boundary Check for Metric Fields (Negative Values)'
\echo '>> Expected Result: 0'
SELECT COUNT(*) AS negative_metrics_count 
FROM silver.yelp_user 
WHERE 
    review_count < 0 OR useful < 0 OR funny < 0 OR cool < 0 OR fans < 0 OR
    compliment_hot < 0 OR compliment_more < 0 OR compliment_profile < 0 OR
    compliment_cute < 0 OR compliment_list < 0 OR compliment_note < 0 OR
    compliment_plain < 0 OR compliment_cool < 0 OR compliment_funny < 0 OR
    compliment_writer < 0 OR compliment_photos < 0;

---
-- 5. Check unwanted spaces
-- Verifica el correcto funcionamiento de las funciones TRIM aplicadas.
\echo '>> Test 5: Leading or Trailing Spaces in Strings'
\echo '>> Expected Result: 0'
SELECT COUNT(*) AS spaces_rows 
FROM silver.yelp_user 
WHERE TRIM(name) <> name OR TRIM(user_id) <> user_id;

-- 6. Check boundaries and consistency in yelping_since field
-- Confirma fechas lógicas de negocio (Yelp se fundó en Octubre de 2004 y nadie puede registrarse en el futuro).
\echo '>> Test 6: Date Boundary Check (yelping_since)'
\echo '>> Expected Result: 0'
SELECT COUNT(*) AS invalid_date_count 
FROM silver.yelp_user 
WHERE yelping_since < '2004-10-01' OR yelping_since > CURRENT_DATE;

---

-- 7. Check boundaries and consistency in average_stars field
-- Verifica que el rango numérico decimal de las estrellas se mantenga strictly entre 1.00 y 5.00.
\echo '>> Test 7: Boundary Check for average_stars (1.00 to 5.00)'
\echo '>> Expected Result: 0'
SELECT COUNT(*) AS invalid_stars_count 
FROM silver.yelp_user 
WHERE average_stars < 1.00 OR average_stars > 5.00;

\echo '====================================================='
\echo 'DATA QUALITY TESTS COMPLETED'
\echo '====================================================='
