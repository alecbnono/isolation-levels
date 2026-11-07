-- DIRTY READ | Session 2 = READER   (open in connection 2, run right after Session 1)
USE stadvdb_ho3;
SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DO SLEEP(2);                                                          -- t2: let S1 do its UPDATE
START TRANSACTION;
SELECT 'R1' AS step, balance FROM accounts WHERE account_id = 101;    -- 700.00 here = DIRTY READ
DO SLEEP(6);                                                          -- S1 rolls back at t6
SELECT 'R2' AS step, balance FROM accounts WHERE account_id = 101;    -- 1000.00 (the 700 never existed)
COMMIT;
