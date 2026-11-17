--Altering the transaction table to add a unique constraint on reference_number and adding foreign key constraints to the purchase, cashout, and transfers tables.
ALTER TABLE transaction ADD UNIQUE(reference_number);
ALTER TABLE purchase ADD FOREIGN KEY (purchase_id) REFERENCES transaction(reference_number);
ALTER TABLE cashout ADD FOREIGN KEY (cashout_id) REFERENCES transaction(reference_number);
ALTER TABLE transfers ADD FOREIGN KEY (transfer_id) REFERENCES transaction(reference_number);