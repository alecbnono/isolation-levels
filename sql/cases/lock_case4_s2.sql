-- PREVENT PHANTOM READS utilizing READ COMMITTED ISOLATION LEVEL
-- BASE CASE: phantom_read_s2.sql
-- PHANTOM READ | Session 2 = INSERTER   (open in connection 2, run SECOND)
-- Mechanism: Explicit Table Lock (i.e. LOCK TABLES accounts READ) [handled by S1]
-- Behavior: INSERT blocks at t=2 because S1 holds a table-level READ lock on accounts.
USE stadvdb_ho3;
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;

DO SLEEP(2);                                                          -- t2: Attempts insert during S1's lock
START TRANSACTION;
-- Blocks at t2 until S1 runs UNLOCK TABLES at t6
INSERT INTO accounts (account_id, customer_id, balance, status)
VALUES (104, 4, 1500.00, 'ACTIVE');
COMMIT;
