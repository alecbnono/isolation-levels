-- PREVENT PHANTOM READS utilizing REPEATABLE READ ISOLATION LEVEL
-- BASE CASE: phantom_read_s2.sql
-- PHANTOM READ | Session 2 = INSERTER   (open in connection 2, run SECOND)
-- Mechanism: Next-Key Locks from a locking read (i.e. SELECT ... WHERE ... FOR UPDATE) [handled by S1]
-- Behavior: INSERT blocks at t=2 because S1's full PRIMARY KEY scan locked the gap after the last row, where id 104 goes.
USE stadvdb_ho3;
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;

DO SLEEP(2);                                                          -- t2: Attempts insert into gap
START TRANSACTION;
-- Blocks at t2 on S1's gap lock after the last PRIMARY KEY row (any balance would block)
INSERT INTO accounts (account_id, customer_id, balance, status)
VALUES (104, 4, 1500.00, 'ACTIVE');
COMMIT;