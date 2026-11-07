-- 02_reset.sql  (wipe data between test runs; then run 01_seed.sql again)
-- Needed because the phantom test inserts account 104 and other tests change balances.
USE stadvdb_ho3;

SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE transactions;
TRUNCATE TABLE accounts;
SET FOREIGN_KEY_CHECKS = 1;
