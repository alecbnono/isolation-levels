-- 01_seed.sql  (initial state; run after 00_schema.sql or after 02_reset.sql)
USE stadvdb_ho3;

INSERT INTO accounts (account_id, customer_id, balance, status) VALUES
(101, 1, 1000.00, 'ACTIVE'),
(102, 2,  500.00, 'ACTIVE'),
(103, 3, 2500.00, 'ACTIVE');

INSERT INTO transactions (account_id, type, amount) VALUES
(101, 'DEPOSIT', 1000.00),
(102, 'DEPOSIT',  500.00),
(103, 'DEPOSIT', 2500.00);
