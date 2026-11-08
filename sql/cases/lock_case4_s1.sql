-- LOCK TIMEOUT BENCHMARK utilizing SERIALIZABLE ISOLATION LEVEL
-- BASE CASE: N/A (Lock Contention Benchmark)
-- LOCK TIMEOUT | Session 1 = LONG LOCK HOLDER   (open in connection 1, run FIRST)
-- Mechanism: Exclusive Record Lock (i.e. SELECT ... FOR UPDATE)
-- Behavior: Holds exclusive lock on account 101 for 6 seconds.
USE stadvdb_ho3;
SET SESSION TRANSACTION ISOLATION LEVEL SERIALIZABLE;

START TRANSACTION;                                                    -- t0
SELECT 'Lock Acquired' AS step, balance FROM accounts WHERE account_id = 101 FOR UPDATE;
DO SLEEP(6);                                                          -- Hold lock for 6s
COMMIT;