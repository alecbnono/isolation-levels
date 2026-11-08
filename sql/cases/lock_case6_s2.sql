-- LOCK GRANULARITY (TABLE) utilizing SERIALIZABLE ISOLATION LEVEL
-- BASE CASE: nonrepeatable_read_s2.sql
-- NON-REPEATABLE READ | Session 2 = WRITER ON AN UNRELATED ROW   (open in connection 2, run SECOND)
-- Mechanism: Explicit Table Lock (i.e. LOCK TABLES accounts WRITE) [handled by S1]
-- Behavior: UPDATE of account 102 blocks at t2 until S1 runs UNLOCK TABLES at t6 (collateral wait).
USE stadvdb_ho3;
SET SESSION TRANSACTION ISOLATION LEVEL SERIALIZABLE;

DO SLEEP(2);                                                          -- t2: while S1 holds the table lock
START TRANSACTION;
UPDATE accounts SET balance = balance + 50.00 WHERE account_id = 102; -- blocks on the table lock
COMMIT;
SELECT 'W committed' AS step, balance FROM accounts WHERE account_id = 102;

