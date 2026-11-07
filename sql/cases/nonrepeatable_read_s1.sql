-- NON-REPEATABLE READ | Session 1 = READER   (run FIRST)
USE stadvdb_ho3;
SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

START TRANSACTION;                                                    -- t0
SELECT 'R1' AS step, balance FROM accounts WHERE account_id = 101;    -- 1000.00
DO SLEEP(6);                                                          -- S2 updates + commits at t2
SELECT 'R2' AS step, balance FROM accounts WHERE account_id = 101;    -- 1200.00 = NON-REPEATABLE; 1000.00 = repeatable
COMMIT;
