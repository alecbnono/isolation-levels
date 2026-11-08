-- LOCK GRANULARITY (ROW) utilizing SERIALIZABLE ISOLATION LEVEL
-- BASE CASE: nonrepeatable_read_s1.sql
-- NON-REPEATABLE READ | Session 1 = READER   (open in connection 1, run FIRST)
-- Mechanism: Exclusive Record Lock (i.e. SELECT ... FOR UPDATE) on account 101 only
-- Behavior: R1 = R2 (anomaly prevented). S2 writes UNRELATED account 102 and should NOT wait,
--           because the PRIMARY KEY lookup locks only the 101 record. Compare with lock_case6.
USE stadvdb_ho3;
SET SESSION TRANSACTION ISOLATION LEVEL SERIALIZABLE;

START TRANSACTION;                                                    -- t0
SELECT 'R1' AS step, balance FROM accounts WHERE account_id = 101 FOR UPDATE;
DO SLEEP(6);                                                          -- S2 updates 102 at t2
SELECT 'R2' AS step, balance FROM accounts WHERE account_id = 101 FOR UPDATE;
COMMIT;                                                               -- t6

