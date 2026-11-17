CREATE DATABASE "operational_db";

\c operational_db

CREATE TABLE customers (
    customer_id  VARCHAR(200)   PRIMARY KEY,
    first_name   VARCHAR(100)   NOT NULL,
    last_name    VARCHAR(100)   NOT NULL,
    email        VARCHAR(255)  UNIQUE,
    phone_number VARCHAR(30)   NOT NULL,
    date_of_birth DATE          NOT NULL,
    created_at   TIMESTAMP     NOT NULL,
    updated_at   TIMESTAMP     NOT NULL
); 

CREATE TABLE accounts (
    account_id   VARCHAR(200)   PRIMARY KEY,
    customer_id  VARCHAR(200)   NOT NULL,
    account_number VARCHAR(34)   UNIQUE,
    account_type VARCHAR(50)   NOT NULL,
    currency_code CHAR(3)    NOT NULL,
    balance      DECIMAL(18,2) NOT NULL,
    status       VARCHAR(20)   NOT NULL,
    opened_at    TIMESTAMP     NOT NULL,
    updated_at   TIMESTAMP     NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE cards (
    card_id      VARCHAR(200)   PRIMARY KEY,
    account_id   VARCHAR(200)   NOT NULL,
    card_number  VARCHAR(19)   UNIQUE,
    card_type    VARCHAR(20)   NOT NULL,
    expiry_month SMALLINT     NOT NULL,
    expiry_year SMALLINT     NOT NULL,
    cvv_hash     VARCHAR(255)  NOT NULL,
    status       VARCHAR(20)   NOT NULL,
    issued_at    TIMESTAMP     NOT NULL,
    updated_at   TIMESTAMP     NOT NULL,
    FOREIGN KEY (account_id) REFERENCES accounts(account_id)
);

CREATE TABLE transaction (
    transaction_id VARCHAR(200)   PRIMARY KEY,
    account_id     VARCHAR(200)   NOT NULL,
    card_id        VARCHAR(200) NULL,
    reference_number VARCHAR(200) NOT NULL,
    transaction_type  VARCHAR(30)   NOT NULL,
    amount         DECIMAL(18,2) NOT NULL,
    currency_code   CHAR(3)    NOT NULL,
    transaction_date TIMESTAMP     NOT NULL,
    updated_at      TIMESTAMP     NOT NULL,
    status         VARCHAR(20)   NOT NULL,
    description     VARCHAR(255)  NULL,
    FOREIGN KEY (account_id) REFERENCES accounts(account_id),
    FOREIGN KEY (card_id) REFERENCES cards(card_id)
);

CREATE TABLE purchase (
    purchase_id   VARCHAR(200)   PRIMARY KEY,
    card_id       VARCHAR(200)   NOT NULL,
    merchant_name   VARCHAR(255)   NOT NULL,
    merchant_category VARCHAR(100)   NOT NULL,
    merchant_country VARCHAR(100)   NULL,
    auth_code      VARCHAR(50)   NULL,
    terminal_id     VARCHAR(50)   NULL,
    FOREIGN KEY (card_id) REFERENCES cards(card_id)
);

CREATE TABLE cashout (
    cashout_id    VARCHAR(200)   PRIMARY KEY,
    account_id    VARCHAR(200)   NOT NULL,
    cashout_channel VARCHAR(30)   NOT NULL,
    fee_amount     DECIMAL(18,2) NOT NULL,
    fee_currency   CHAR(3)    NOT NULL,
    cashout_amount   DECIMAL(18,2) NOT NULL,
    cashout_currency CHAR(3)    NOT NULL,
    cashout_date   TIMESTAMP     NOT NULL,
    location        VARCHAR(255)  NULL,
    FOREIGN KEY (account_id) REFERENCES accounts(account_id)
);

CREATE TABLE transfers (
    transfer_id   VARCHAR(200)   PRIMARY KEY,
    source_account_id VARCHAR(200)   NOT NULL,
    destination_account_id VARCHAR(200)   NOT NULL,
    transfer_method VARCHAR(30)   NOT NULL,
    settled_at TIMESTAMP     NOT NULL,
    note VARCHAR(255)  NULL,
    FOREIGN KEY (source_account_id) REFERENCES accounts(account_id),
    FOREIGN KEY (destination_account_id) REFERENCES accounts(account_id)
);