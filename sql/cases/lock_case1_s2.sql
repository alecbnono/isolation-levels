-- PREVENT DIRTY READS utilizing READ UNCOMMITTED ISOLATION LEVEL
-- BASE CASE: dirty-read_s2.sql
-- LOCK CASE 1 | Session 2 = READER (Pessimistic Lock; open in connection 2, run right after Session 1)
-- Mechanism: Exclusive Record Lock (i.e. SELECT ... FOR UPDATE)
-- Behavior: Force S2 to wait for S1's ROLLBACK @ t=6. Returns 1000.00 instead of 700.00.
USE stadvdb_ho3;
SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DO SLEEP(2);                                                          -- t2: Runs after S1 update
START TRANSACTION;
-- Explicit FOR UPDATE forces S2 to block here until S1 rolls back at t6
SELECT 'R1' AS step, balance FROM accounts WHERE account_id = 101 FOR UPDATE;
DO SLEEP(2);
SELECT 'R2' AS step, balance FROM accounts WHERE account_id = 101 FOR UPDATE;
COMMIT;