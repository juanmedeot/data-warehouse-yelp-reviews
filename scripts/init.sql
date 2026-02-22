/*
===============================================================================
PostgreSQL Data Warehouse Initialization Script
===============================================================================

Description:
This script initializes a PostgreSQL data warehouse environment by:
1. Creating the `datawarehouse` database only if it does not already exist
2. Connecting to the newly created database
3. Creating the Medallion Architecture schemas:
   - bronze 
   - silver
   - gold 

Execution Requirements:
This script MUST be executed using the PostgreSQL CLI (psql).
It uses psql meta-commands (\gexec, \c) which are NOT supported in GUI SQL clients.

How to Run:
From terminal:
-Connect to PostgreSQL: psql -U postgres -h localhost -p 5432
-Run file: \i init.sql

- The script should be run while connected to a default database
  (e.g., postgres), NOT to the target datawarehouse database.
- Safe to re-run.
===============================================================================
*/

-- Create database only if it does not exist
SELECT 'CREATE DATABASE datawarehouse'
WHERE NOT EXISTS (
    SELECT FROM pg_database WHERE datname = 'datawarehouse'
)\gexec

-- Connect to the new database
\c datawarehouse

-- Create schemas
CREATE SCHEMA IF NOT EXISTS bronze;
CREATE SCHEMA IF NOT EXISTS silver;
CREATE SCHEMA IF NOT EXISTS gold;

