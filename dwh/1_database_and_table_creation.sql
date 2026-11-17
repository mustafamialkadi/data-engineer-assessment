CREATE DATABASE "warehouse_db";

\c warehouse_db

CREATE TABLE dim_customer (
    customer_id  VARCHAR(200)   PRIMARY KEY,
    first_name   VARCHAR(100)   NOT NULL,
    last_name    VARCHAR(100)   NOT NULL,
    email        VARCHAR(255)  UNIQUE,
    phone_number VARCHAR(30)   NOT NULL,
    date_of_birth DATE          NOT NULL,
    created_at   TIMESTAMP     NOT NULL,
    updated_at   TIMESTAMP     NOT NULL
); 

CREATE TABLE dim_account (
    account_id   VARCHAR(200)   PRIMARY KEY,
    customer_id  VARCHAR(200)   NOT NULL,
    account_number VARCHAR(34)   UNIQUE,
    account_type VARCHAR(50)   NOT NULL,
    currency_code CHAR(3)    NOT NULL,
    balance      DECIMAL(18,2) NOT NULL,
    status       VARCHAR(20)   NOT NULL,
    opened_at    TIMESTAMP     NOT NULL,
    updated_at   TIMESTAMP     NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES dim_customer(customer_id)
);

CREATE TABLE dim_card (
    card_id      VARCHAR(200)   PRIMARY KEY,
    account_id   VARCHAR(200)   NOT NULL,
    card_type    VARCHAR(20)   NOT NULL,
    expiry_month SMALLINT     NOT NULL,
    expiry_year SMALLINT     NOT NULL,
    status       VARCHAR(20)   NOT NULL,
    issued_at    TIMESTAMP     NOT NULL,
    updated_at   TIMESTAMP     NOT NULL,
    FOREIGN KEY (account_id) REFERENCES dim_account(account_id)
);

CREATE TABLE dim_date (
    date_id      DATE          PRIMARY KEY,
    year         SMALLINT     NOT NULL,
    quarter      SMALLINT     NOT NULL,
    month        SMALLINT     NOT NULL,
    month_name   VARCHAR(20)   NOT NULL,
    day          SMALLINT     NOT NULL,
    day_of_week  SMALLINT     NOT NULL,
    is_weekend   BOOLEAN      NOT NULL
);

CREATE TABLE fact_purchase (
    purchase_id    VARCHAR(200)   PRIMARY KEY,
    account_id     VARCHAR(200)   NOT NULL,
    customer_id    VARCHAR(200)   NOT NULL,
    card_id        VARCHAR(200)  NULL,
    date_id        DATE          NOT NULL,
    merchant_name  VARCHAR(255)  NOT NULL,
    merchant_country   VARCHAR(100)  NULL,
    merchant_category  VARCHAR(100)    NOT NULL,
    amount         DECIMAL(18,2) NOT NULL,
    currency_code   CHAR(3)    NOT NULL,
    transaction_date TIMESTAMP     NOT NULL,
    updated_at      TIMESTAMP     NOT NULL,
    status         VARCHAR(20)   NOT NULL,
    FOREIGN KEY (account_id) REFERENCES dim_account(account_id),
    FOREIGN KEY (customer_id) REFERENCES dim_customer(customer_id),
    FOREIGN KEY (card_id) REFERENCES dim_card(card_id),
    FOREIGN KEY (date_id) REFERENCES dim_date(date_id)
    
);

CREATE TABLE fact_cashout (
    cashout_id     VARCHAR(200)   PRIMARY KEY,
    account_id     VARCHAR(200)   NOT NULL,
    customer_id    VARCHAR(200)   NOT NULL,
    card_id        VARCHAR(200)  NULL,
    date_id        DATE          NOT NULL,
    fee_amount     DECIMAL(18,2) NOT NULL,
    fee_currency CHAR(3)    NOT NULL,
    cashout_channel VARCHAR(30)  NOT NULL,
    amount         DECIMAL(18,2) NOT NULL,
    location  VARCHAR(255)  NULL,
    currency_code   CHAR(3)    NOT NULL,
    transaction_date TIMESTAMP     NOT NULL,
    updated_at      TIMESTAMP     NOT NULL,
    status         VARCHAR(20)   NOT NULL,
    FOREIGN KEY (account_id) REFERENCES dim_account(account_id),
    FOREIGN KEY (customer_id) REFERENCES dim_customer(customer_id),
    FOREIGN KEY (card_id) REFERENCES dim_card(card_id),
    FOREIGN KEY (date_id) REFERENCES dim_date(date_id)
);

CREATE TABLE fact_transfer (
    transfer_id    VARCHAR(200)   PRIMARY KEY,
    account_id     VARCHAR(200)   NOT NULL,
    customer_id    VARCHAR(200)   NOT NULL,
    date_id        DATE          NOT NULL,
    amount         DECIMAL(18,2) NOT NULL,
    transfer_method VARCHAR(30)   NOT NULL,
    source_account_id VARCHAR(200)   NOT NULL,
    destination_account_id VARCHAR(200)   NOT NULL,
    settled_at     TIMESTAMP     NOT NULL,
    note           VARCHAR(255)  NULL,
    currency_code   CHAR(3)    NOT NULL,
    transaction_date TIMESTAMP     NOT NULL,
    updated_at      TIMESTAMP     NOT NULL,
    status         VARCHAR(20)   NOT NULL,
    FOREIGN KEY (account_id) REFERENCES dim_account(account_id),
    FOREIGN KEY (customer_id) REFERENCES dim_customer(customer_id),
    FOREIGN KEY (date_id) REFERENCES dim_date(date_id),
    FOREIGN KEY (source_account_id) REFERENCES dim_account(account_id),
    FOREIGN KEY (destination_account_id) REFERENCES dim_account(account_id)
);