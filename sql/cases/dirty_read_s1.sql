-- DIRTY READ | Session 1 = WRITER   (open in connection 1, run FIRST)
-- Change the isolation level line for each of the 4 runs (the Python runner rewrites it for you).
USE stadvdb_ho3;
SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

START TRANSACTION;                                                    -- t0
UPDATE accounts SET balance = balance - 300.00 WHERE account_id = 101; -- 1000 -> 700 (uncommitted)
SELECT 'W after update' AS step, balance FROM accounts WHERE account_id = 101;
DO SLEEP(6);                                                          -- hold the uncommitted change
ROLLBACK;                                                             -- t6: undo -> back to 1000
SELECT 'W after rollback' AS step, balance FROM accounts WHERE account_id = 101;
