Lock benchmark @ SERIALIZABLE: 4 workers x 5 txns, hold=0.2s per txn

| Mode | Total runtime | Ideal runtime | Throughput (txn/s) | Avg latency | Max latency | Errors |
|---|---|---|---|---|---|---|
| row | 1.18s | 1.00s | 16.93 | 0.22s | 0.22s | 0 |
| row-hot | 4.39s | 4.00s | 4.56 | 0.80s | 0.87s | 0 |
| table | 4.44s | 4.00s | 4.51 | 0.81s | 0.88s | 0 |
