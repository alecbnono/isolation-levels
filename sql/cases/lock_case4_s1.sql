-- PREVENT PHANTOM READS utilizing READ COMMITTED ISOLATION LEVEL
-- BASE CASE: phantom_read_s1.sql
-- PHANTOM READ | Session 1 = RANGE READER   (open in connection 1, run FIRST)
-- Mechanism: Explicit Table Lock (i.e. LOCK TABLES accounts READ)
-- Behavior: Other sessions can read accounts but cannot write to it, so S2's INSERT waits until UNLOCK TABLES at t=6.
-- NOTE: Do NOT add START TRANSACTION here. It implicitly releases table locks, and the phantom returns.
USE stadvdb_ho3;
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;

LOCK TABLES accounts READ;                                            -- t0
SELECT 'P1' AS step, account_id, balance FROM accounts WHERE balance >= 800.00 ORDER BY account_id;
DO SLEEP(6);                                                          -- S2 attempts INSERT at t2
SELECT 'P2' AS step, account_id, balance FROM accounts WHERE balance >= 800.00 ORDER BY account_id;
UNLOCK TABLES;                                                        -- t6: S2's INSERT proceeds
