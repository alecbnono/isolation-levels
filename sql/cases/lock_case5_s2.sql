-- LOCK GRANULARITY (ROW) utilizing SERIALIZABLE ISOLATION LEVEL
-- BASE CASE: nonrepeatable_read_s2.sql
-- NON-REPEATABLE READ | Session 2 = WRITER ON AN UNRELATED ROW   (open in connection 2, run SECOND)
-- Mechanism: Exclusive Record Lock (i.e. SELECT ... FOR UPDATE) [handled by S1]
-- Behavior: UPDATE of account 102 completes immediately at t2 (no collateral wait).
USE stadvdb_ho3;
SET SESSION TRANSACTION ISOLATION LEVEL SERIALIZABLE;

DO SLEEP(2);                                                          -- t2: while S1 holds the 101 lock
START TRANSACTION;
UPDATE accounts SET balance = balance + 50.00 WHERE account_id = 102; -- different row: no conflict
COMMIT;
SELECT 'W committed' AS step, balance FROM accounts WHERE account_id = 102;

