-- ============================================
-- FlowServer Demo: Database Creation
-- ============================================
-- Description: Creates the 'albaraka' database for the demo
-- Prerequisites: PostgreSQL/WarehousePG running
-- Usage: psql -h localhost -p 5432 -U gpadmin -d postgres -f 01_create_database.sql
-- ============================================

-- Drop database if exists (WARNING: destroys all data)
DROP DATABASE IF EXISTS albaraka;

-- Create database
CREATE DATABASE albaraka
  WITH OWNER = gpadmin
       ENCODING = 'UTF8'
       TABLESPACE = pg_default
       CONNECTION LIMIT = -1;

\echo '✓ Database "albaraka" created successfully'

-- Connect to new database
\c albaraka

\echo '✓ Connected to database "albaraka"'
\echo 'Next step: Run 02_create_tables.sql'
