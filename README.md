# Yelp Reviews Data Warehouse (PostgreSQL)

End-to-end **Data Warehouse** project built on **PostgreSQL** using the **Medallion Architecture (Bronze, Silver, Gold)** and a **Snowflake Schema** dimensional model to analyze reviews, businesses, and users from the **Yelp Academic Dataset**.

---

## Architecture Overview

The pipeline processes raw JSON datasets through three progressive layers:

1. **Bronze Layer (`bronze`)**: Raw ingestion of the Yelp JSON datasets (`business`, `review`, `user`) into staging tables with ingestion metadata (`ingested_at`), preserving source fidelity.
2. **Silver Layer (`silver`)**: Data cleansing, JSONB parsing, strict SQL type casting (`DATE`, `INTEGER`, `NUMERIC`, `JSONB`), whitespace trimming, and data quality validation.
3. **Gold Layer (`gold`)**: Analytical **Snowflake Schema** implemented via **Materialized Views** (`MATERIALIZED VIEW`), featuring numeric surrogate keys (`user_key`, `business_key`, `review_key`), an `UNKNOWN (-1)` member pattern for orphan handling, flattened 1:N sub-dimensions, and domain business rules.

Visual diagrams for the end-to-end flow and dimensional schema are located in [`docs/`](./docs/):
- [`docs/data_flow_yelp_dw.png`](./docs/data_flow_yelp_dw.png) — Medallion data flow diagram.
- [`docs/gold_yelp_dw_diagram.png`](./docs/gold_yelp_dw_diagram.png) — Gold layer Snowflake schema diagram.

---

## Gold Layer Dimensional Model (Snowflake)

### Core Dimensions & Sub-Dimensions
- **`gold.dim_user`**: User dimension with surrogate key `user_key`, natural key `user_id`, activity metrics, compliments, and a default `-1` (`UNKNOWN`) row.
- **`gold.dim_user_friend`**: Flattened 1:N friend network (`PK`: `user_key + friend_user_id`, `FK`: `user_key` $\rightarrow$ `gold.dim_user`).
- **`gold.dim_user_elite`**: Flattened 1:N Yelp Elite membership years (`PK`: `user_key + elite_year`, `FK`: `user_key` $\rightarrow$ `gold.dim_user`).
- **`gold.dim_business`**: Business dimension with surrogate key `business_key`, natural key `business_id`, geolocation, ratings, open status, and a default `-1` (`UNKNOWN`) row.
- **`gold.dim_business_category`**: Flattened 1:N business categories (`PK`: `business_key + category_name`, `FK`: `business_key` $\rightarrow$ `gold.dim_business`).
- **`gold.dim_business_hours`**: Flattened 1:N daily operating schedules (`PK`: `business_key + day_number`, `FK`: `business_key` $\rightarrow$ `gold.dim_business`), capturing `open_time`, `close_time`, `closes_next_day`, `is_24h`, and `open_duration_hours`.

### Fact Table
- **`gold.fact_review`**: Review fact table (`PK`: `review_key`, `NK`: `review_id`, `FK`: `user_key`, `FK`: `business_key`) with star ratings, engagement counters (`useful`, `funny`, `cool`), review text, and review date. Orphan keys are safely mapped to `-1` via `COALESCE`.

---

## Repository Structure

```text
data-warehouse-yelp-reviews/
├── datasets/
│   └── datasets.md                             # Instructions and source links for Yelp Academic Dataset
├── docs/
│   ├── data_flow_yelp_dw.png                   # End-to-end Medallion data flow diagram
│   ├── gold_yelp_dw_diagram.png                # Gold Snowflake ER/dimensional diagram
│   ├── architecture_and_etl.md                 # Medallion architecture, execution order & performance notes
│   ├── gold_data_model.md                      # Data dictionary, keys, grain & business rules
│   └── data_quality_and_testing.md             # Silver & Gold data quality validation strategy
├── scripts/
│   ├── init.sql                                # Database & schemas initialization (bronze, silver, gold)
│   ├── bronze/
│   │   ├── ddl_bronze.sql                      # Bronze layer table definitions
│   │   └── data_ingestion_bronze.sql           # Raw JSON ingestion into Bronze
│   ├── silver/
│   │   ├── ddl_silver.sql                      # Silver layer table definitions
│   │   └── data_ingestion_silver.sql           # Bronze-to-Silver cleansing & type casting ETL
│   └── gold/
│       └── data_ingestion_gold.sql             # Silver-to-Gold Snowflake Materialized Views & indexes
├── tests/
│   ├── silver/
│   │   ├── silver_yelp_business_test.sql       # Silver business data quality checks
│   │   ├── silver_yelp_review_test.sql         # Silver review data quality checks
│   │   └── silver_yelp_user_test.sql           # Silver user data quality checks
│   └── gold/
│       └── gold_mv_tests.sql                   # Gold dimensional & referential integrity checks
├── .env                                        # Local environment variables template
├── .gitignore
├── LICENSE
└── README.md
```

---

## Getting Started & Execution Order

### Prerequisites
- **PostgreSQL 14+** (with `psql` CLI available).
- **Yelp Academic Dataset** files downloaded locally (see [`datasets/datasets.md`](./datasets/datasets.md)).

### Step-by-Step Pipeline Execution

Run the scripts sequentially from the terminal using `psql`:

```bash
# 1. Initialize database and schemas (bronze, silver, gold)
psql -h <host> -U <user> -d postgres -f "scripts/init.sql"

# 2. Bronze Layer: Create tables and ingest raw JSON datasets
psql -h <host> -U <user> -d datawarehouse -f "scripts/bronze/ddl_bronze.sql"
psql -h <host> -U <user> -d datawarehouse -f "scripts/bronze/data_ingestion_bronze.sql"

# 3. Silver Layer: Create typed tables and run cleansing transformations
psql -h <host> -U <user> -d datawarehouse -f "scripts/silver/ddl_silver.sql"
psql -h <host> -U <user> -d datawarehouse -f "scripts/silver/data_ingestion_silver.sql"

# 4. Run Silver Data Quality Tests
psql -h <host> -U <user> -d datawarehouse -f "tests/silver/silver_yelp_business_test.sql"
psql -h <host> -U <user> -d datawarehouse -f "tests/silver/silver_yelp_review_test.sql"
psql -h <host> -U <user> -d datawarehouse -f "tests/silver/silver_yelp_user_test.sql"

# 5. Gold Layer: Build Snowflake Materialized Views and indexes
psql -h <host> -U <user> -d datawarehouse -f "scripts/gold/data_ingestion_gold.sql"

# 6. Run Gold Dimensional & Referential Integrity Tests
psql -h <host> -U <user> -d datawarehouse -f "tests/gold/gold_mv_tests.sql"
```

---

## Documentation

For detailed technical specifications, explore the `docs/` directory:
- **[Architecture & ETL Pipeline](./docs/architecture_and_etl.md)**
- **[Gold Layer Data Model & Business Rules](./docs/gold_data_model.md)**
- **[Data Quality & Testing Strategy](./docs/data_quality_and_testing.md)**

---

## License

This project is licensed under the terms specified in [`LICENSE`](./LICENSE).
