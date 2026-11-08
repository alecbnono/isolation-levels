#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.9"
# dependencies = ["pymysql"]
# ///
"""
Runs the 12 baseline cases (3 anomalies x 4 isolation levels) with two real connections.

Usage:
  pip install pymysql
  python3 run_cases.py --user root --password secret                 # all 12
  python3 run_cases.py --user root --password secret --case dirty --level RC
Env alternatives: MYSQL_HOST, MYSQL_PORT, MYSQL_USER, MYSQL_PASSWORD.

For each case it: resets+reseeds data -> starts S1 and S2 at the same instant (Barrier) ->
S2's own DO SLEEP offsets the interleaving -> logs every SELECT / error with timestamps
-> decides whether the anomaly occurred -> writes logs/ and results/summary.md.
"""
import argparse, os, re, sys, threading, time
from pathlib import Path
import pymysql
import pymysql.cursors

ROOT = Path(__file__).resolve().parent.parent
SQL = ROOT / "sql"
LEVELS = {
    "RU": "READ UNCOMMITTED",
    "RC": "READ COMMITTED",
    "RR": "REPEATABLE READ",
    "SER": "SERIALIZABLE",
}
CASES = ["dirty", "nonrepeatable", "phantom"]
LOCK_CASES = ["lock1", "lock2", "lock3", "lock4"]
FILES = {"dirty": "dirty_read", "nonrepeatable": "nonrepeatable_read", "phantom": "phantom_read", 
         "lock1": "lock_case1", "lock2": "lock_case2", "lock3": "lock_case3", "lock4": "lock_case4"}
LOCK_LEVEL = {"lock1": "RU", "lock2": "RC", "lock3": "RR", "lock4": "SER"}


# Expected outcome on InnoDB (True = anomaly visible)
EXPECTED = {
    ("dirty", "RU"): "ANOMALY", ("dirty", "RC"): "none", ("dirty", "RR"): "none", ("dirty", "SER"): "none",
    ("nonrepeatable", "RU"): "ANOMALY", ("nonrepeatable", "RC"): "ANOMALY",
    ("nonrepeatable", "RR"): "none", ("nonrepeatable", "SER"): "none",
    ("phantom", "RU"): "ANOMALY", ("phantom", "RC"): "ANOMALY",
    ("phantom", "RR"): "write-only", ("phantom", "SER"): "none",
}

LOCK_EXPECTED = {"lock1": "PREVENTED (Blocked)", "lock2": "PREVENTED (Repeatable)",
                 "lock3": "PREVENTED (Gap Locked)", "lock4": "TIMEOUT_CAPTURED (Error 1205)"}


def split_statements(text):
    text = re.sub(r"--[^\n]*", "", text)
    return [s.strip() for s in text.split(";") if s.strip()]


def connect(args, lock_case=False):
    init = None
    if lock_case and args.lock_timeout:
        init = f"SET SESSION innodb_lock_wait_timeout = {int(args.lock_timeout)}"
    return pymysql.connect(
        host=args.host, port=args.port, user=args.user, password=args.password,
        autocommit=True, cursorclass=pymysql.cursors.DictCursor,
        read_timeout=120, write_timeout=120, init_command=init
    )


def run_file(path, conn):
    for stmt in split_statements(Path(path).read_text()):
        with conn.cursor() as cur:
            cur.execute(stmt)


def reset(args):
    conn = connect(args)
    try:
        run_file(SQL / "setup" / "02_reset.sql", conn)
        run_file(SQL / "setup" / "01_seed.sql", conn)
    finally:
        conn.close()


def run_session(name, path, level, args, barrier, t0_box, log, results):
    """Executes one session script; records timestamped events."""
    stmts = split_statements(Path(path).read_text())

    if "lock" not in Path(path).name:
        stmts = [re.sub(r"(?i)^SET SESSION TRANSACTION ISOLATION LEVEL [A-Z ]+$",
                    f"SET SESSION TRANSACTION ISOLATION LEVEL {LEVELS[level]}", s) for s in stmts]
    conn = connect(args)


    try:
        barrier.wait()
        if t0_box[0] is None:
            t0_box[0] = time.time()
        for stmt in stmts:
            t_start = time.time() - t0_box[0]
            m = re.match(r"(?is)select\s+'([^']+)'\s+as\s+step", stmt)
            label = m.group(1) if m else None
            try:
                with conn.cursor() as cur:
                    cur.execute(stmt)
                    rows = cur.fetchall() if cur.description else None
                    affected = cur.rowcount
                t_end = time.time() - t0_box[0]
                if rows is not None and label:
                    rows = [{k: (float(v) if hasattr(v, "as_tuple") else v) for k, v in r.items()} for r in rows]
                    results[(name, label)] = rows
                    log.append((t_end, name, f"{label}: {rows}  (waited {t_end - t_start:.1f}s)"))
                else:
                    short = " ".join(stmt.split())[:70]
                    log.append((t_end, name, f"{short}  -> affected={affected} (took {t_end - t_start:.1f}s)"))
            except Exception as e:  # lock wait timeout, deadlock, etc.
                t_end = time.time() - t0_box[0]
                log.append((t_end, name, f"ERROR on '{' '.join(stmt.split())[:50]}': {e}"))
                results[(name, "error")] = str(e)
                break
    finally:
        conn.close()

def expected_for(case, level):
    return LOCK_EXPECTED[case] if case in LOCK_CASES else EXPECTED[(case, level)]


def judge(case, results):
    g = lambda s, l: results.get((s, l))
    ids = lambda x: [r["account_id"] for r in x] if x is not None else None

    # -- LOCKING EXPERIMENT EVALUATIONS --
    if case in ("lock1", "lock2", "lock3") and any(k[1] == "error" for k in results):
        return "ERROR"
    if case == "lock1":
        r1 = g("S2", "R1")
        return "PREVENTED (Blocked)" if r1 and r1[0]["balance"] == 1000.0 else "ANOMALY (Dirty Read)"
    if case == "lock2":
        r1, r2 = g("S1", "R1"), g("S1", "R2")
        return "PREVENTED (Repeatable)" if r1 and r2 and r1[0]["balance"] == r2[0]["balance"] else "ANOMALY (Non-Repeatable)" 
    if case == "lock3":
        p1, p2 = ids(g("S1", "P1")), ids(g("S1", "P2"))
        return "PREVENTED (Gap Locked)" if p1 is not None and p2 is not None and p1 == p2 else "ANOMALY (Phantom Insert)"
    if case == "lock4":
        s2_err = results.get(("S2", "error"), "")
        return "TIMEOUT_CAPTURED (Error 1205)" if "1205" in s2_err or "Lock wait timeout" in s2_err else "NO_TIMEOUT"

    # -- BASE EXPERIMENT EVALUATION --
    if any(k[1] == "error" for k in results):
        return "ERROR"
    
    if case == "dirty":
        r1 = g("S2", "R1")
        return "ANOMALY" if r1 and r1[0]["balance"] == 700.0 else "none"
    if case == "nonrepeatable":
        r1, r2 = g("S1", "R1"), g("S1", "R2")
        return "ANOMALY" if r1 and r2 and r1[0]["balance"] != r2[0]["balance"] else "none"
    if case == "phantom":
        ids = lambda x: [r["account_id"] for r in x] if x is not None else None
        p1, p2, p3 = ids(g("S1", "P1")), ids(g("S1", "P2")), ids(g("S1", "P3"))
        if p1 is not None and p2 is not None and p1 != p2:
            return "ANOMALY"
        if p1 is not None and p3 is not None and p1 != p3:
            return "write-only"
        return "none"
    return "?"


def run_case(case, level, args):
    reset(args)
    f = FILES[case]
    barrier = threading.Barrier(2)
    t0_box, log, results = [None], [], {}
    threads = [
        threading.Thread(target=run_session, args=("S1", SQL / "cases" / f"{f}_s1.sql", level, args, barrier, t0_box, log, results)),
        threading.Thread(target=run_session, args=("S2", SQL / "cases" / f"{f}_s2.sql", level, args, barrier, t0_box, log, results)),
    ]
    start = time.time()
    for t in threads: t.start()
    for t in threads: t.join()
    log.sort(key=lambda e: e[0])
    verdict = judge(case, results)
    text = [f"=== {case.upper()} @ {LEVELS[level]} ===  (total {time.time() - start:.1f}s)"]
    text += [f"[t={t:5.1f}s] {s}: {msg}" for t, s, msg in log]
    text.append(f"VERDICT: {verdict}   (expected on InnoDB: {expected_for(case, level)})")
    return verdict, "\n".join(text)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--host", default=os.getenv("MYSQL_HOST", "127.0.0.1"))
    ap.add_argument("--port", type=int, default=int(os.getenv("MYSQL_PORT", "3306")))
    ap.add_argument("--user", default=os.getenv("MYSQL_USER", "root"))
    ap.add_argument("--password", default=os.getenv("MYSQL_PASSWORD", ""))
    ap.add_argument("--case", choices=CASES + LOCK_CASES)
    ap.add_argument("--mode", choices=["baseline", "locks", "all"], default="all")
    ap.add_argument("--level", choices=list(LEVELS))
    ap.add_argument("--lock-timeout", type=int, default=None,
                    help="innodb_lock_wait_timeout (seconds) for lock-case sessions; "
                         "default: server value (50s). Keep it above S1's SLEEP for cases "
                         "where S2 is expected to wait and then succeed.")
    args = ap.parse_args()

    cases = [args.case] if args.case else {"baseline": CASES, "locks": LOCK_CASES, "all": CASES + LOCK_CASES}[args.mode]
    levels = [args.level] if args.level else list(LEVELS)
    (ROOT / "logs").mkdir(exist_ok=True)
    (ROOT / "results").mkdir(exist_ok=True)

    rows = []
    for c in cases:
        # lock cases run once, at the level their SQL file is written for
        for l in ([LOCK_LEVEL[c]] if c in LOCK_CASES else levels):
            verdict, text = run_case(c, l, args)
            print(text, "\n")
            (ROOT / "logs" / f"{c}_{l}.log").write_text(text + "\n")
            rows.append((c, LEVELS[l], verdict, expected_for(c, l)))
 
    out = ["| Case | Isolation level | Observed | Expected (InnoDB) | Match |", "|---|---|---|---|---|"]
    for c, l, v, e in rows:
        out.append(f"| {c} | {l} | {v} | {e} | {'yes' if v == e else '**NO**'} |")
    summary = "\n".join(out)
    print(summary)
    (ROOT / "results" / "summary.md").write_text(summary + "\n")


if __name__ == "__main__":
    sys.exit(main())