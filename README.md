# Yelp Data Warehouse (Medallion Architecture - PostgreSQL)

## Overview
This repository contains a Data Warehouse built using the Yelp Open Dataset.

The warehouse is designed following the Medallion Architecture (Bronze, Silver, Gold) and implemented in PostgreSQL. Its main purpose is to support data analysis projects, dashboards, and machine learning workflows using structured and scalable data models.

Raw Yelp JSON files are ingested directly into PostgreSQL JSONB Bronze tables and transformed into structured Silver and Gold layers.

The implementation approach and best practices were inspired by educational content from the YouTube channels *Data with Baraa* and *Ankit Bansal*.

## Objectives
- Centralize Yelp open data into a structured Data Warehouse
- Enable efficient analytical querying
- Provide clean and reliable datasets for BI dashboards
- Serve as a data foundation for Machine Learning projects
- Practice modern Data Engineering concepts using PostgreSQL

## Dataset
Source: Yelp Open Dataset  
Link: https://business.yelp.com/data/resources/open-dataset/

The dataset includes:
- Businesses
- Reviews
- Users
- Check-ins
- Tips
*Photos where not included

## Architecture
The Data Warehouse follows the Medallion Architecture:

### Bronze Layer (Raw)
- Stores raw data ingested directly from the Yelp JSON files
- Minimal transformation
- Preserves original structure and schema
- Used for traceability and reprocessing

### Silver Layer (Cleaned & Transformed)
- Data cleaning and standardization
- Schema normalization
- Data quality checks
- Handling nulls, duplicates, and type casting
- Structured relational tables ready for analysis

### Gold Layer (Business & Analytics)
- Aggregated and business-ready datasets
- Star/Snowflake schemas where applicable
- Fact and dimension tables
- Optimized for dashboards and ML feature consumption

## Tech Stack
- Database: PostgreSQL
- Data Source: Yelp Open Dataset (JSON)
- Architecture: Medallion (Bronze, Silver, Gold)

## Use Cases
- Exploratory Data Analysis (EDA)
- Business Intelligence Dashboards
- Customer and Business Analytics
- Machine Learning Feature Engineering
- Data Modeling Practice Projects


## Data Pipeline (High-Level)
1. Ingest raw Yelp JSON datasets into Bronze tables
2. Transform and clean data into Silver layer
3. Build analytical models in Gold layer
4. Use Gold datasets for dashboards and ML projects


## Future Improvements
- Incremental data loading
- Orchestration with ETL tools (e.g., Airflow or Azure Data Factory)
- Data quality monitoring
- Indexing and performance optimization
- Automated testing for transformations

## License
This project uses publicly available Yelp Open Dataset and under MIT License.
  
