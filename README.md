# Concurrency experiments: setup + dual-session scripts

## One-time setup
1. Run `sql/setup/00_schema.sql` (creates database `stadvdb_ho3`; Sakila is NOT required), then `sql/setup/01_seed.sql`.
2. Install [uv](https://docs.astral.sh/uv/). The runner declares its own deps (pymysql) inline, so no venv/pip step.

## Automated run (all 12 cases)
    ./runner/run_cases.py --password <pw>
    ./runner/run_cases.py --password <pw> --case phantom --level RR
    # equivalent: uv run runner/run_cases.py --password <pw>
    # or set MYSQL_PASSWORD=<pw> once and drop --password

Writes `logs/<case>_<level>.log` (timestamped evidence) and `results/summary.md`.
Levels: RU, RC, RR, SER. Cases: dirty, nonrepeatable, phantom.

## Manual run (Workbench / two terminals)
1. Run `sql/setup/02_reset.sql` then `01_seed.sql`.
2. Edit the `SET SESSION TRANSACTION ISOLATION LEVEL ...` line in BOTH files of the pair.
3. Start `<case>_s1.sql` in connection 1, then `<case>_s2.sql` in connection 2 within ~1 second.
   Sleep offsets (S2 waits 2s, S1 holds 6s) enforce the order.

## Notes
- At SERIALIZABLE the S2 write blocks until S1 ends (~4s wait in the log). That is expected, not a hang.
- Phantom at REPEATABLE READ: plain SELECT shows no phantom (snapshot); P3 (after UPDATE) does. Verdict "write-only".
