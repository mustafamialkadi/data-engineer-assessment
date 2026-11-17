--Checking if all the transactions are linked to the corresponding purchase, cashout, and transfer records.
SELECT COUNT(*) FROM purchase p
WHERE NOT EXISTS (SELECT 1 FROM transaction tx WHERE tx.reference_number = p.purchase_id);

SELECT COUNT(*) FROM cashout c
WHERE NOT EXISTS (SELECT 1 FROM transaction tx WHERE tx.reference_number = c.cashout_id);

SELECT COUNT(*) FROM transfers t
WHERE NOT EXISTS (SELECT 1 FROM transaction tx WHERE tx.reference_number = t.transfer_id);


--Checking for duplicate transactions based on reference_number.
SELECT reference_number, COUNT(*) AS transaction_count FROM transaction
GROUP BY reference_number 
HAVING COUNT(*) > 1;


--Checking for transactions that have a transaction_date earlier than the account's opened_at date.
SELECT COUNT(*) FROM transaction t
JOIN accounts a ON a.account_id = t.account_id
WHERE t.transaction_date < a.opened_at;


--Seeing the distinct status values in the accounts table so that we can check for any transactions linked to accounts with status that are not 'active'.
SELECT DISTINCT status FROM accounts;


--Checking for transactions that are linked to accounts with status that are not 'active'. These transactions should not exist as per the business rules. Note: these transactions could have been made before the account was closed, but we are checking for any transactions that are linked to accounts that are currently not active.
SELECT COUNT(*) FROM transaction t
JOIN accounts a ON a.account_id = t.account_id
WHERE a.status NOT IN ('ACTIVE');


--Checking the number of transactions that are linked to cards that have expired. Extracting the year and month from the transaction_date and comparing it with the expiry_year and expiry_month of the card.
SELECT COUNT(*) FROM cards c
JOIN transaction t ON t.card_id = c.card_id
WHERE (EXTRACT(YEAR FROM t.transaction_date), EXTRACT(MONTH FROM t.transaction_date)) > (c.expiry_year, c.expiry_month);


--Checking the number of accounts that were opened before the customer turned 18 years old.
SELECT COUNT(*) FROM accounts a
join customers c on a.customer_id = c.customer_id
WHERE a.opened_at < c.date_of_birth + INTERVAL '18 years';