-- PREVENT NON-REPEATABLE READS utilizing READ COMMITTED ISOLATION LEVEL
-- BASE CASE: nonrepeatable_read_s1.sql
-- NON-REPEATABLE READ | Session 1 = READER   (open in connection 1, run FIRST)
-- Mechanism: Shared Record Lock (i.e. SELECT ... FOR SHARE)
-- Behavior: Locks row for reading; blocks S2's UPDATE at t=2 until S1 commits at t=6.
USE stadvdb_ho3;
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;

START TRANSACTION;                                                    -- t0
-- FOR SHARE permits concurrent reads but blocks concurrent edits
SELECT 'R1' AS step, balance FROM accounts WHERE account_id = 101 FOR SHARE;
DO SLEEP(6);                                                          -- S2 attempts UPDATE at t2
SELECT 'R2' AS step, balance FROM accounts WHERE account_id = 101 FOR SHARE;
COMMIT;