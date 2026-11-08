-- PREVENT PHANTOM READS utilizing REPEATABLE READ ISOLATION LEVEL
-- BASE CASE: phantom_read_s1.sql
-- PHANTOM READ | Session 1 = RANGE READER   (open in connection 1, run FIRST)
-- Mechanism: Next-Key Locks from a locking read (i.e. SELECT ... WHERE ... FOR UPDATE)
-- Behavior: balance has no index, so the query scans the whole PRIMARY KEY and next-key locks every row and gap.
USE stadvdb_ho3;
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;

START TRANSACTION;                                                    -- t0
-- Full PRIMARY KEY scan: locks all rows and gaps, not only balance >= 800.00
SELECT 'P1' AS step, account_id, balance FROM accounts WHERE balance >= 800.00 FOR UPDATE;
DO SLEEP(6);                                                          -- S2 attempts INSERT at t2
SELECT 'P2' AS step, account_id, balance FROM accounts WHERE balance >= 800.00 FOR UPDATE;
COMMIT;