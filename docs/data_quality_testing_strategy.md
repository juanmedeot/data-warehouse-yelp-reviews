# Data Quality & Testing Strategy

Quality assurance is split across layers so each stage validates its specific responsibilities without redundant computation.

---

## 1. Silver Layer Tests (`tests/silver/`)

Scripts:
- `tests/silver/silver_yelp_business_test.sql`
- `tests/silver/silver_yelp_review_test.sql`
- `tests/silver/silver_yelp_user_test.sql`

### Focus Areas
1. **Bronze-to-Silver Completeness**: Verifies zero row loss (`COUNT(silver) - COUNT(bronze) = 0`).
2. **Natural Key Uniqueness**: Ensures zero duplicate `business_id`, `review_id`, or `user_id` values.
3. **Critical Nulls & JSONB Leaks**: Detects residual `'null'` strings, empty keys, or missing mandatory fields.
4. **Domain & Chronological Boundaries**:
   - Non-negative counters (`review_count`, `useful`, `funny`, `cool`, `fans`, compliments).
   - Valid rating ranges (`1.00` to `5.00`).
   - Valid geographic coordinates (`latitude` $\in [-90, 90]$, `longitude` $\in [-180, 180]$).
   - Dates bounded between Yelp's founding (`2004-10-01`) and `CURRENT_DATE`.
5. **String Hygiene**: Verifies no leading or trailing whitespace (`TRIM(col) <> col`).

---

## 2. Gold Layer Tests (`tests/gold/gold_mv_tests.sql`)

Rather than repeating Silver's raw data type and string checks, Gold tests validate **dimensional modeling integrity**:

1. **Row Count & Sentinel Member Alignment**:
   - `gold.dim_user` equals `silver.yelp_user + 1` (`user_key = -1`).
   - `gold.dim_business` equals `silver.yelp_business + 1` (`business_key = -1`).
   - `gold.fact_review` matches `silver.yelp_review` 1:1.
   - Explicit verification that `-1` (`UNKNOWN`) exists in both core dimensions.
2. **Surrogate & Composite Grain Uniqueness**:
   - Confirms zero duplicate keys across `user_key`, `business_key`, `review_key`, `(user_key, friend_user_id)`, `(user_key, elite_year)`, `(business_key, category_name)`, and `(business_key, day_number)`.
3. **Referential Integrity & Orphan Fallback Monitoring**:
   - Ensures `0` `NULL` foreign keys in `fact_review` and all Snowflake sub-dimensions.
   - Ensures `0` broken foreign keys (every FK resolves to an existing parent PK).
   - Audits the percentage of `fact_review` rows mapped to `-1` (`pct_orphan_user`, `pct_orphan_business`) to detect unexpected join degradation.
4. **Gold Business Rule Verification**:
   - `dim_business_hours`: Validates `day_number` $\in [1, 7]$, non-null times, `0 < open_duration_hours <= 24.0`, exact `24.0` duration when `is_24h = TRUE`, and consistency between `closes_next_day` and `close_time < open_time`.
   - `dim_user_elite`: Validates `elite_year` boundaries (`2005` to current year).