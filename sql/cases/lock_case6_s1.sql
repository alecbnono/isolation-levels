-- LOCK GRANULARITY (TABLE) utilizing SERIALIZABLE ISOLATION LEVEL
-- BASE CASE: nonrepeatable_read_s1.sql
-- NON-REPEATABLE READ | Session 1 = READER   (open in connection 1, run FIRST)
-- Mechanism: Explicit Table Lock (i.e. LOCK TABLES accounts WRITE)
-- Behavior: R1 = R2 (anomaly prevented), but the whole table is locked, so S2's write to the
--           UNRELATED account 102 waits until UNLOCK TABLES at t6. Compare with lock_case5.
-- NOTE: Do NOT add START TRANSACTION here. It implicitly releases table locks.
USE stadvdb_ho3;
SET SESSION TRANSACTION ISOLATION LEVEL SERIALIZABLE;

LOCK TABLES accounts WRITE;                                           -- t0
SELECT 'R1' AS step, balance FROM accounts WHERE account_id = 101;
DO SLEEP(6);                                                          -- S2 attempts update of 102 at t2
SELECT 'R2' AS step, balance FROM accounts WHERE account_id = 101;
UNLOCK TABLES;                                                        -- t6: S2's UPDATE proceeds

