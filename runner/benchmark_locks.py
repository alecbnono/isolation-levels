#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.9"
# dependencies = ["pymysql"]
# ///
"""
Lock-granularity performance benchmark (supports the lock experiments' trade-off discussion).

N worker threads each run K short transactions concurrently. Every transaction reads a row,
"works" for --hold seconds (DO SLEEP) while holding its lock, then updates the row. Modes:

  row      SELECT ... FOR UPDATE, each worker on its OWN row   (disjoint work, fine-grained lock)
  row-hot  SELECT ... FOR UPDATE, all workers on the SAME row  (contended work, fine-grained lock)
  table    LOCK TABLES accounts WRITE, each worker on its own row (disjoint work, coarse lock)

Ideal runtimes: row ~ K*hold, row-hot ~ N*K*hold, table ~ N*K*hold.
So "table" pays the full serialization cost even though the workers never touch the same row.

Usage:
  ./runner/benchmark_locks.py --password <pw>
  ./runner/benchmark_locks.py --password <pw> --workers 8 --iterations 5 --hold 0.2 --level SER
Writes results/lock_benchmark.md and logs/lock_benchmark.log.
"""
import argparse, os, statistics, sys, threading, time

from run_cases import LEVELS, ROOT, connect, reset

BENCH_BASE_ID = 200          # worker i uses account 201+i (inserted by setup_rows)
MODES = ["row", "row-hot", "table"]


def setup_rows(args):
    reset(args)
    conn = connect(args)
    try:
        with conn.cursor() as cur:
            cur.execute("USE stadvdb_ho3")
            for i in range(args.workers):
                cur.execute(
                    "INSERT INTO accounts (account_id, customer_id, balance, status) "
                    "VALUES (%s, 1, 1000.00, 'ACTIVE')", (BENCH_BASE_ID + 1 + i,))
    finally:
        conn.close()


def worker(idx, mode, args, barrier, latencies, errors):
    account = BENCH_BASE_ID + 1 if mode == "row-hot" else BENCH_BASE_ID + 1 + idx
    conn = connect(args)
    try:
        with conn.cursor() as cur:
            cur.execute("USE stadvdb_ho3")
            cur.execute(f"SET SESSION TRANSACTION ISOLATION LEVEL {LEVELS[args.level]}")
        barrier.wait()
        for _ in range(args.iterations):
            t0 = time.time()
            try:
                with conn.cursor() as cur:
                    if mode == "table":
                        # No START TRANSACTION: it would implicitly release the table lock.
                        cur.execute("LOCK TABLES accounts WRITE")
                        cur.execute("SELECT balance FROM accounts WHERE account_id = %s", (account,))
                        cur.execute("DO SLEEP(%s)", (args.hold,))
                        cur.execute("UPDATE accounts SET balance = balance + 1.00 WHERE account_id = %s", (account,))
                        cur.execute("UNLOCK TABLES")
                    else:
                        cur.execute("START TRANSACTION")
                        cur.execute("SELECT balance FROM accounts WHERE account_id = %s FOR UPDATE", (account,))
                        cur.execute("DO SLEEP(%s)", (args.hold,))
                        cur.execute("UPDATE accounts SET balance = balance + 1.00 WHERE account_id = %s", (account,))
                        cur.execute("COMMIT")
                latencies.append(time.time() - t0)
            except Exception as e:  # lock wait timeout / deadlock
                errors.append(str(e))
                with conn.cursor() as cur:
                    cur.execute("ROLLBACK")
                    cur.execute("UNLOCK TABLES")
    finally:
        conn.close()


def run_mode(mode, args):
    setup_rows(args)
    barrier = threading.Barrier(args.workers)
    latencies, errors = [], []
    threads = [threading.Thread(target=worker, args=(i, mode, args, barrier, latencies, errors))
               for i in range(args.workers)]
    start = time.time()
    for t in threads: t.start()
    for t in threads: t.join()
    total = time.time() - start
    done = len(latencies)
    return {
        "mode": mode,
        "total": total,
        "txns": done,
        "tps": done / total if total else 0.0,
        "avg": statistics.mean(latencies) if latencies else 0.0,
        "max": max(latencies) if latencies else 0.0,
        "ideal": args.iterations * args.hold * (1 if mode == "row" else args.workers),
        "errors": len(errors),
    }


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--host", default=os.getenv("MYSQL_HOST", "127.0.0.1"))
    ap.add_argument("--port", type=int, default=int(os.getenv("MYSQL_PORT", "3306")))
    ap.add_argument("--user", default=os.getenv("MYSQL_USER", "root"))
    ap.add_argument("--password", default=os.getenv("MYSQL_PASSWORD", ""))
    ap.add_argument("--workers", type=int, default=4)
    ap.add_argument("--iterations", type=int, default=5, help="transactions per worker")
    ap.add_argument("--hold", type=float, default=0.2, help="seconds each transaction holds its lock")
    ap.add_argument("--level", choices=list(LEVELS), default="SER")
    ap.add_argument("--mode", choices=MODES)
    args = ap.parse_args()
    args.lock_timeout = None  # used by run_cases.connect

    results = [run_mode(m, args) for m in ([args.mode] if args.mode else MODES)]
    reset(args)  # leave the standard seed state behind

    header = (f"Lock benchmark @ {LEVELS[args.level]}: {args.workers} workers x {args.iterations} txns, "
              f"hold={args.hold}s per txn")
    out = [header, "",
           "| Mode | Total runtime | Ideal runtime | Throughput (txn/s) | Avg latency | Max latency | Errors |",
           "|---|---|---|---|---|---|---|"]
    for r in results:
        out.append(f"| {r['mode']} | {r['total']:.2f}s | {r['ideal']:.2f}s | {r['tps']:.2f} | "
                   f"{r['avg']:.2f}s | {r['max']:.2f}s | {r['errors']} |")
    text = "\n".join(out)
    print(text)
    (ROOT / "logs").mkdir(exist_ok=True)
    (ROOT / "results").mkdir(exist_ok=True)
    (ROOT / "results" / "lock_benchmark.md").write_text(text + "\n")
    (ROOT / "logs" / "lock_benchmark.log").write_text(text + "\n")


if __name__ == "__main__":
    sys.exit(main())

