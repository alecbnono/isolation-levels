-- PREVENT NON-REPEATABLE READS utilizing READ COMMITTED ISOLATION LEVEL
-- BASE CASE: nonrepeatable_read_s2.sql
-- NON-REPEATABLE READ | Session 2 = WRITER   (open in connection 2, run SECOND)
-- Mechanism: Shared Record Lock (i.e. SELECT ... FOR SHARE) [handled by S1]
-- Behavior: UPDATE blocks at t=2 because S1 holds FOR SHARE on account 101.
USE stadvdb_ho3;
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;

DO SLEEP(2);                                                          -- t2: Attempts update mid-transaction
START TRANSACTION;
-- Blocks at t2 because S1 holds FOR SHARE on account 101
UPDATE accounts SET balance = balance + 200.00 WHERE account_id = 101;
COMMIT;
SELECT 'W committed' AS step, balance FROM accounts WHERE account_id = 101;