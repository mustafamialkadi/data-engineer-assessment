-- Manual walkthrough, run step by step: the SELECT/UPDATE steps in operational_db, the commented commands in PowerShell.
--Find the first pending purchase transaction.
SELECT reference_number, status, updated_at FROM transaction
WHERE transaction_type = 'PURCHASE' AND status = 'PENDING' LIMIT 1;
--PUR000004 | PENDING | 2025-12-08 11:35:26 was the first pending purchase transaction.

--Updating the status of the first pending purchase transaction to 'SETTLED' and updating the updated_at timestamp to the current time.
UPDATE transaction
SET status = 'SETTLED', updated_at = NOW()
WHERE reference_number = 'PUR000004';

--Checking the status and updated_at timestamp of the transaction after the update.
SELECT reference_number, status, updated_at FROM transaction
WHERE reference_number = 'PUR000004';

--Reloading the data warehouse to reflect the changes made in the operational database.
-- (In POWERSHELL) psql -U postgres -d warehouse_db -f dwh/3_etl_load.sql

--Checking the status and updated_at timestamp of the transaction in the data warehouse after reloading.
-- (In POWERSHELL) psql -U postgres -d warehouse_db -c "SELECT purchase_id, status, updated_at FROM fact_purchase WHERE purchase_id = 'PUR000004';"
-- PUR000004 | SETTLED | 2026-11-17 22:45:15.508627 was the status and updated_at timestamp of the transaction in the data warehouse after reloading meaning the ETL process successfully updated the fact_purchase table with the latest information from the operational database.