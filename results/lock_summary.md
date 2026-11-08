| Case | Isolation level | Observed | Expected (InnoDB) | Match |
|---|---|---|---|---|
| lock1 | READ UNCOMMITTED | PREVENTED (Blocked) | PREVENTED (Blocked) | yes |
| lock2 | READ COMMITTED | PREVENTED (Repeatable) | PREVENTED (Repeatable) | yes |
| lock3 | REPEATABLE READ | PREVENTED (Gap Locked) | PREVENTED (Gap Locked) | yes |
| lock4 | READ COMMITTED | PREVENTED (Table Locked) | PREVENTED (Table Locked) | yes |
