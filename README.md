# Data Engineer Technical Assessment

## Tools I used

Postgres is used for both the operational database and the data warehouse, as two separate databases (`operational_db` and `warehouse_db`). I went with it because I'm familiar with it, as I mentioned in our first meeting, it's open source, and it's reliable for transactional workloads.

One trade-off I'm aware of is that Postgres stores data row by row. That's fine at this size for this assessment, but for a production warehouse at scale I'd move to a columnar engine, since analytical queries usually read a few columns across many rows. I suspect that's the kind of setup the bank uses, though I don't know its backend.

Everything is done through scripts run from the command line with psql, no GUI, so the whole setup can be rebuilt from scratch by running the scripts in order.

## Repository structure

```
data/   the CSV files, the ERD and validation_summary.csv as provided by you
opr/    Task 1: operational database
dwh/    Task 2: data warehouse and ETL
docs/   the assessment PDF
```

The number at the start of each file name is the order to run it in.

## How to run it

Built and tested on PostgreSQL 18, with `psql` on the PATH. Run the commands from the project folder.

1. `psql -U postgres -f opr/1_database_and_table_creation.sql` creates `operational_db` and its 7 tables
2. `psql -U postgres -d operational_db -f opr/2_data_load.sql` loads the CSVs (run from the project folder so the `data/` paths work)
3. `psql -U postgres -d operational_db -f opr/3_data_check.sql` runs my data checks
4. `psql -U postgres -d operational_db -f opr/4_table_alter.sql` adds the subtype foreign keys
5. `psql -U postgres -f dwh/1_database_and_table_creation.sql` creates `warehouse_db` and its tables
6. In `dwh/2_etl_setup.sql`, replace `YOUR_PASSWORD` with your postgres password, then run `psql -U postgres -d warehouse_db -f dwh/2_etl_setup.sql`
7. `psql -U postgres -d warehouse_db -f dwh/3_etl_load.sql` loads the warehouse (rerun it any time to pick up changes)
8. `dwh/4_change_test.sql` is a step-by-step walkthrough proving the update works, not a script to run in one go

Both creation scripts have `\c` right after `CREATE DATABASE` so the tables get created inside the new database and not in the default `postgres` one.

## Task 1: Operational database

I built the 7 tables exactly as the ERD shows them, including its names. The ERD mixes plural and singular names (CUSTOMERS, ACCOUNTS, CARDS, TRANSFERS vs TRANSACTION, PURCHASE, CASHOUT) and the csv file is called `transactions.csv`, but I followed the ERD since the task says to use it.

I created the tables in foreign key order, parents before children: customers → accounts → cards → transaction → purchase / cashout / transfers.

`transaction.card_id` is marked NULL in the ERD, but there's an "initiates" line from CARDS to TRANSACTION, so I made it an optional foreign key: if a transaction has a card it has to be a real card, but transfers and most cashouts don't have one.

For loading I used psql's `\copy` instead of `COPY`, because `\copy` reads the file as me rather than as the Postgres server account, which usually can't read files on my Desktop. I set the encoding to UTF8 explicitly since the files are UTF-8 with BOM, and `HEADER true` skips the first line, so the BOM doesn't end up in a column name.

All 7 files loaded with no constraint errors and the row counts match `validation_summary.csv` exactly: 10,000 customers, 11,000 accounts, 16,000 cards, 225,000 transactions and 75,000 each for purchase, cashout and transfers.

I tested the scripts end to end from empty tables (drop, create, load) to make sure they rebuild the database.

## Assumptions (and one that turned out wrong)

The ERD says PURCHASE, CASHOUT and TRANSFERS "specialize" TRANSACTION, but none of them has a column pointing back to it. My first assumption was that they reuse the transaction's ID, so `purchase_id` would equal `transaction_id`. I tested it before enforcing anything and it was wrong: 0 out of 75,000 IDs matched in all three tables (transaction IDs start with TXN, purchase IDs with PUR).

Looking at the data, the real link is `transaction.reference_number`: a purchase transaction's reference number is the `purchase_id` (prefixes PUR / CSH / TRF, which is what the "Reference mapping" line in `validation_summary.csv` was hinting at). I checked it and all 225,000 subtype rows have a matching transaction, and there are no duplicate reference numbers. Only after verifying that did I add a UNIQUE constraint on `reference_number` and the three foreign keys (`opr/4_table_alter.sql`). So the approach was: verify first, then enforce.

## Data observations

I didn't change or delete any of the provided data. I loaded it as is and I'm reporting what I found:

- **34,588 transactions (about 15%) are dated before their account was opened.** That's impossible, so it's a data quality issue.
- **9,618 transactions used a card after its expiry month.** I treated a card as valid until the end of its expiry month.
- **89,579 transactions (about 40%) are on accounts that are currently DORMANT or SUSPENDED.** One caveat: the account status is only the current status with no history, so I can't tell if the account was inactive at the time of the transaction. It needs review rather than being a definite error, and it's an argument for keeping history in the warehouse.
- **437 accounts were opened before the customer turned 18.** This might be allowed (guardian accounts), so I'm flagging it as a policy question, not an error.
- **The ERD makes `transfers.settled_at` NOT NULL**, so even FAILED, PENDING and REVERSED transfers have a settlement time, which doesn't make sense for a transfer that never settled.
- **The ERD is inconsistent on the subtypes:** CASHOUT repeats the amount, currency and date that are already on TRANSACTION, while PURCHASE and TRANSFERS rely on the transaction's amount. My checks showed the cashout copies match exactly, so in the warehouse I only take the values from the transaction.

## Task 2: Data warehouse and ETL

### Design

I used a star schema with dimensions and fact tables.

Dimensions:
- `dim_customer`, `dim_account`, `dim_card`: copied from the operational tables, using the same IDs as keys
- `dim_date`: one row per day across the transaction date range, with year, quarter, month, weekday and an `is_weekend` flag. I set the weekend as Friday and Saturday since that's the weekend here in Iraq. The `generate_series` query for it was based on a reference example rather than written from scratch; I adapted it and can explain how it works.

Facts, one per business process:
- `fact_purchase`, `fact_cashout`, `fact_transfer`: one row per purchase / cashout / transfer, 75,000 each

I first had a shared `fact_transaction` table on top of the three, but I dropped it. Each fact table carries what it needs on its own (customer, account, card, date, amount, currency, status, transaction date) so it can be reported on directly, the same way the flat reports I use at work (like Overdue or Direct_Facilities) have the customer and account on every row without looking anything up. The trade-off is that a total across all three types needs a `UNION ALL`, so a view combining them would be a good next step.

Things I left out or kept on purpose:
- I didn't bring `cvv_hash` or the full `card_number` into the warehouse; analysts don't need them and it's safer that way.
- I kept customer contact details (email, phone) and `account_number`, because real reports use them (for example the Customer_Details report I work with). In production I'd restrict who can see those columns, with roles or a view that hides them from general analysts.
- Every table keeps `updated_at`, because the update process depends on it.

### How the ETL works

The warehouse reads the operational database directly using `postgres_fdw`, a Postgres extension. `dwh/2_etl_setup.sql` connects `warehouse_db` to `operational_db` and imports the operational tables into a schema called `staging`, so the whole ETL is plain SQL:

- **Extract:** read from `staging.customers`, `staging.transaction`, and so on
- **Transform:** join each purchase / cashout / transfer to its transaction (on `reference_number`) and to its account (to get `customer_id`), and turn the transaction timestamp into a date for `dim_date`
- **Load:** insert into the warehouse tables, dimensions first, then facts

### Updating the warehouse

The load is written as upserts (`INSERT ... ON CONFLICT DO UPDATE`): new rows get inserted, and rows that already exist get refreshed with the latest values. That means the same script does both the first full load and every update after it. Rerunning it gives the same counts and creates no duplicates.

To prove it, I took the first PENDING purchase (PUR000004, last updated 2025-12-08), changed it to SETTLED in the operational database with `updated_at` set to now, reran the load, and the warehouse row showed SETTLED with the new timestamp. The steps are in `dwh/4_change_test.sql`. The test changed that one row; I've since rebuilt the operational database from the CSVs, so it's back to its original value.

Final counts in the warehouse: 10,000 customers, 11,000 accounts, 16,000 cards, 365 days, and 75,000 rows in each fact table.

## Limitations and what I'd do with more time

- **History tracking (SCD Type 2):** right now an update overwrites the old value. Keeping history (start date, end date, current flag) would let us know, for example, whether an account was dormant at the time of a transaction.
- **Only process what changed:** each run upserts everything. At a bigger scale I'd only pick up rows whose `updated_at` is newer than the last run.
- **A view combining the three fact tables** for totals across all transaction types.
- **A dedicated database user** with only the permissions it needs, instead of running everything as the `postgres` superuser.
- **A columnar warehouse engine** for production scale.
- **More checks:** for example ACTIVE cards that are already past their expiry date, and customers under 18 at the time they signed up.
