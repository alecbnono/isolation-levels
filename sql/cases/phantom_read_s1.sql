-- PHANTOM READ | Session 1 = READER   (run FIRST)
USE stadvdb_ho3;
SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

START TRANSACTION;                                                    -- t0
SELECT 'P1' AS step, account_id, balance FROM accounts WHERE balance >= 800.00 ORDER BY account_id;
                                                                      -- 101, 103
DO SLEEP(6);                                                          -- S2 inserts 104 + commits at t2
SELECT 'P2' AS step, account_id, balance FROM accounts WHERE balance >= 800.00 ORDER BY account_id;
                                                                      -- 101,103,104 => phantom (plain SELECT)

-- EXTENSION (needed for InnoDB REPEATABLE READ): a plain SELECT uses the snapshot and hides 104,
-- but a WRITE over the same range touches the committed row, which then becomes visible.
UPDATE accounts SET status = 'FLAGGED' WHERE balance >= 800.00;
SELECT 'P3' AS step, account_id, balance FROM accounts WHERE balance >= 800.00 ORDER BY account_id;
COMMIT;
