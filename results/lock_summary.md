| Case | Isolation level | Observed | Expected (InnoDB) | Match | S2 lock wait | Total runtime |
|---|---|---|---|---|---|---|
| lock1 | READ UNCOMMITTED | PREVENTED (Blocked) | PREVENTED (Blocked) | yes | 4.0s | 8.1s |
| lock2 | READ COMMITTED | PREVENTED (Repeatable) | PREVENTED (Repeatable) | yes | 4.0s | 6.1s |
| lock3 | REPEATABLE READ | PREVENTED (Gap Locked) | PREVENTED (Gap Locked) | yes | 4.0s | 6.1s |
| lock4 | READ COMMITTED | PREVENTED (Table Locked) | PREVENTED (Table Locked) | yes | 4.0s | 6.1s |
| lock5 | SERIALIZABLE | NO COLLATERAL WAIT (Row Lock) | NO COLLATERAL WAIT (Row Lock) | yes | 0.0s | 6.1s |
| lock6 | SERIALIZABLE | COLLATERAL WAIT (Table Lock) | COLLATERAL WAIT (Table Lock) | yes | 4.0s | 6.1s |
