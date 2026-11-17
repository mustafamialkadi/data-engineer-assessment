CREATE EXTENSION IF NOT EXISTS postgres_fdw;

CREATE SERVER operational_server
    FOREIGN DATA WRAPPER postgres_fdw
    OPTIONS (host 'localhost', port '5432', dbname 'operational_db');

CREATE USER MAPPING FOR postgres
    SERVER operational_server
    OPTIONS (user 'postgres', password 'YOUR_PASSWORD');

-- Make the operational tables visible here under a "staging" schema
CREATE SCHEMA staging;
IMPORT FOREIGN SCHEMA public FROM SERVER operational_server INTO staging;