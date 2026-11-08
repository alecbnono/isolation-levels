-- PREVENT PHANTOM READS utilizing REPEATABLE READ ISOLATION LEVEL
-- BASE CASE: phantom_read_s1.sql
-- PHANTOM READ | Session 1 = RANGE READER   (open in connection 1, run FIRST)
-- Mechanism: Range / Next-Key Lock (i.e. SELECT ... WHERE ... FOR UPDATE)
-- Behavior: Next-Key lock covers matching records and index gaps in range >= 800.00.
USE stadvdb_ho3;
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;

START TRANSACTION;                                                    -- t0
-- Next-Key lock covers matching records AND index gaps in range >= 800.00
SELECT 'P1' AS step, account_id, balance FROM accounts WHERE balance >= 800.00 FOR UPDATE;
DO SLEEP(6);                                                          -- S2 attempts INSERT at t2
SELECT 'P2' AS step, account_id, balance FROM accounts WHERE balance >= 800.00 FOR UPDATE;
COMMIT;