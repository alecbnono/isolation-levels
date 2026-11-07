-- NON-REPEATABLE READ | Session 2 = WRITER
USE stadvdb_ho3;
SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DO SLEEP(2);                                                          -- t2: after S1's first read
START TRANSACTION;
UPDATE accounts SET balance = balance + 200.00 WHERE account_id = 101; -- 1000 -> 1200
COMMIT;                                                               -- (blocks until t6 under SERIALIZABLE)
SELECT 'W committed' AS step, balance FROM accounts WHERE account_id = 101;
