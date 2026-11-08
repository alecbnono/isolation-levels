-- PREVENT DIRTY READS utilizing READ UNCOMMITTED ISOLATION LEVEL
-- BASE CASE: dirty-read_s1.sql
-- DIRTY READ | Session 1 = WRITER   (open in connection 1, run FIRST)
-- Mechanism: Exclusive Record Lock (i.e. SELECT ... FOR UPDATE) [handled by S2]
-- Behavior: Force S2 to wait for S1's ROLLBACK @ t=6. Returns 1000.00 instead of 700.00.
USE stadvdb_ho3;
SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

START TRANSACTION;                                                    -- t0
UPDATE accounts SET balance = balance - 300.00 WHERE account_id = 101; -- 1000 -> 700 (uncommitted)
SELECT 'W after update' AS step, balance FROM accounts WHERE account_id = 101;
DO SLEEP(6);                                                          -- hold the uncommitted change
ROLLBACK;                                                             -- t6: undo -> back to 1000
SELECT 'W after rollback' AS step, balance FROM accounts WHERE account_id = 101;
