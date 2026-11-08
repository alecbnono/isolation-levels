-- PREVENT PHANTOM READS utilizing REPEATABLE READ ISOLATION LEVEL
-- BASE CASE: phantom_read_s2.sql
-- PHANTOM READ | Session 2 = INSERTER   (open in connection 2, run SECOND)
-- Mechanism: Range / Next-Key Lock (i.e. SELECT ... WHERE ... FOR UPDATE) [handled by S1]
-- Behavior: INSERT blocks at t=2 because balance 1500.00 falls in S1's active gap lock.
USE stadvdb_ho3;
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;

DO SLEEP(2);                                                          -- t2: Attempts insert into gap
START TRANSACTION;
-- Blocks at t2 because 1500.00 falls into S1's active Next-Key lock range
INSERT INTO accounts (account_id, customer_id, balance, status)
VALUES (104, 4, 1500.00, 'ACTIVE');
COMMIT;