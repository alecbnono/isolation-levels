-- LOCK TIMEOUT BENCHMARK utilizing SERIALIZABLE ISOLATION LEVEL
-- BASE CASE: N/A (Lock Contention Benchmark)
-- LOCK TIMEOUT | Session 2 = SHORT TIMEOUT CONTENDER   (open in connection 2, run SECOND)
-- Mechanism: Session Timeout Limiter (i.e. SET session innodb_lock_wait_timeout = 2)
-- Behavior: Waits 2 seconds for S1's lock, then fails cleanly with Error 1205.
USE stadvdb_ho3;
SET SESSION TRANSACTION ISOLATION LEVEL SERIALIZABLE;
-- Set session lock wait timeout to 2s (less than S1's 6s sleep)
SET session innodb_lock_wait_timeout = 2;

DO SLEEP(1);                                                          -- t1: Executes while S1 holds lock
START TRANSACTION;
-- Waits 2 seconds for S1's lock, then fails with Error 1205
SELECT 'Contending Read' AS step, balance FROM accounts WHERE account_id = 101 FOR UPDATE;
COMMIT;