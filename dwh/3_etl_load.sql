INSERT INTO dim_customer (customer_id, first_name, last_name, email, phone_number, date_of_birth, created_at, updated_at)
SELECT
    customer_id,
    first_name,
    last_name,
    email,
    phone_number,
    date_of_birth,
    created_at,
    updated_at
FROM staging.customers
ON CONFLICT (customer_id) DO UPDATE SET
    first_name = EXCLUDED.first_name,
    last_name = EXCLUDED.last_name,
    email = EXCLUDED.email,
    phone_number = EXCLUDED.phone_number,
    date_of_birth = EXCLUDED.date_of_birth,
    created_at = EXCLUDED.created_at,
    updated_at = EXCLUDED.updated_at;

INSERT INTO dim_account (account_id, customer_id, account_number, account_type, currency_code, balance, status, opened_at, updated_at)
SELECT
    account_id,
    customer_id,
    account_number,
    account_type,
    currency_code,
    balance,
    status,
    opened_at,
    updated_at
FROM staging.accounts
ON CONFLICT (account_id) DO UPDATE SET
    customer_id = EXCLUDED.customer_id,
    account_number = EXCLUDED.account_number,
    account_type = EXCLUDED.account_type,
    currency_code = EXCLUDED.currency_code,
    balance = EXCLUDED.balance,
    status = EXCLUDED.status,
    opened_at = EXCLUDED.opened_at,
    updated_at = EXCLUDED.updated_at;

INSERT INTO dim_card (card_id, account_id, card_type, expiry_month, expiry_year, status, issued_at, updated_at)
SELECT
    card_id,
    account_id,
    card_type,
    expiry_month,
    expiry_year,
    status,
    issued_at,
    updated_at
FROM staging.cards
ON CONFLICT (card_id) DO UPDATE SET
    account_id = EXCLUDED.account_id,
    card_type = EXCLUDED.card_type,
    expiry_month = EXCLUDED.expiry_month,
    expiry_year = EXCLUDED.expiry_year,
    status = EXCLUDED.status,
    issued_at = EXCLUDED.issued_at,
    updated_at = EXCLUDED.updated_at;

INSERT INTO dim_date (date_id, year, quarter, month, month_name, day, day_of_week, is_weekend)
SELECT
    d::date,
    EXTRACT(YEAR FROM d),
    EXTRACT(QUARTER FROM d),
    EXTRACT(MONTH FROM d),
    TRIM(TO_CHAR(d, 'Month')),
    EXTRACT(DAY FROM d),
    EXTRACT(ISODOW FROM d),          -- 1 = Monday ... 7 = Sunday
    EXTRACT(ISODOW FROM d) IN (5, 6) -- Friday and Saturday
FROM generate_series(
    (SELECT MIN(transaction_date)::date FROM staging.transaction),
    (SELECT MAX(transaction_date)::date FROM staging.transaction),
    INTERVAL '1 day'
) AS d
ON CONFLICT (date_id) DO NOTHING;

INSERT INTO fact_purchase (purchase_id, account_id, customer_id, card_id, date_id, merchant_name, merchant_country, merchant_category, amount, currency_code, transaction_date, updated_at, status)
SELECT
    p.purchase_id,
    t.account_id,
    a.customer_id,            
    t.card_id,
    t.transaction_date::date, 
    p.merchant_name,
    p.merchant_country,
    p.merchant_category,
    t.amount,
    t.currency_code,
    t.transaction_date,
    t.updated_at,
    t.status
FROM staging.purchase p
JOIN staging.transaction t ON t.reference_number = p.purchase_id
JOIN staging.accounts    a ON a.account_id = t.account_id
ON CONFLICT (purchase_id) DO UPDATE SET
    status     = EXCLUDED.status,
    amount     = EXCLUDED.amount,
    transaction_date = EXCLUDED.transaction_date,
    merchant_name = EXCLUDED.merchant_name,
    merchant_country = EXCLUDED.merchant_country,
    merchant_category = EXCLUDED.merchant_category,
    updated_at = EXCLUDED.updated_at;

INSERT INTO fact_cashout (cashout_id, account_id, customer_id, card_id, date_id, fee_amount, fee_currency, cashout_channel, amount, location, currency_code, transaction_date, updated_at, status)
SELECT
    c.cashout_id,
    t.account_id,
    a.customer_id,            
    t.card_id,
    t.transaction_date::date, 
    c.fee_amount,
    c.fee_currency,
    c.cashout_channel,
    t.amount,
    c.location,
    t.currency_code,
    t.transaction_date,
    t.updated_at,
    t.status
FROM staging.cashout c
JOIN staging.transaction t ON t.reference_number = c.cashout_id
JOIN staging.accounts a ON a.account_id = t.account_id
ON CONFLICT (cashout_id) DO UPDATE SET
    status     = EXCLUDED.status,
    amount     = EXCLUDED.amount,
    updated_at = EXCLUDED.updated_at,
    location    = EXCLUDED.location,
    fee_amount  = EXCLUDED.fee_amount,
    fee_currency = EXCLUDED.fee_currency,
    cashout_channel = EXCLUDED.cashout_channel,
    currency_code = EXCLUDED.currency_code,
    transaction_date = EXCLUDED.transaction_date;

INSERT INTO fact_transfer (transfer_id, account_id, customer_id, date_id, amount, transfer_method, source_account_id, destination_account_id, settled_at, note, currency_code, transaction_date, updated_at, status)
SELECT
    tr.transfer_id,
    t.account_id,
    a.customer_id,            
    t.transaction_date::date, 
    t.amount,
    tr.transfer_method,
    tr.source_account_id,
    tr.destination_account_id,
    tr.settled_at,
    tr.note,
    t.currency_code,
    t.transaction_date,
    t.updated_at,
    t.status
FROM staging.transfers tr
JOIN staging.transaction t ON t.reference_number = tr.transfer_id
JOIN staging.accounts a ON a.account_id = t.account_id
ON CONFLICT (transfer_id) DO UPDATE SET
    status     = EXCLUDED.status,
    amount     = EXCLUDED.amount,
    updated_at = EXCLUDED.updated_at,
    transfer_method = EXCLUDED.transfer_method,
    source_account_id = EXCLUDED.source_account_id,
    destination_account_id = EXCLUDED.destination_account_id,
    settled_at = EXCLUDED.settled_at,
    note = EXCLUDED.note,
    currency_code = EXCLUDED.currency_code,
    transaction_date = EXCLUDED.transaction_date;