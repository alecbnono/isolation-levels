-- PHANTOM READ | Session 2 = INSERTER
USE stadvdb_ho3;
SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DO SLEEP(2);                                                          -- t2: after S1's first query
START TRANSACTION;
INSERT INTO accounts (account_id, customer_id, balance, status)
VALUES (104, 4, 1500.00, 'ACTIVE');                                   -- (blocks until t6 under SERIALIZABLE)
COMMIT;
