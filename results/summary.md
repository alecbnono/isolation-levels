| Anomaly | Isolation level | Observed | Expected (InnoDB) | Match |
|---|---|---|---|---|
| dirty | READ UNCOMMITTED | ANOMALY | ANOMALY | yes |
| dirty | READ COMMITTED | none | none | yes |
| dirty | REPEATABLE READ | none | none | yes |
| dirty | SERIALIZABLE | none | none | yes |
| nonrepeatable | READ UNCOMMITTED | ANOMALY | ANOMALY | yes |
| nonrepeatable | READ COMMITTED | ANOMALY | ANOMALY | yes |
| nonrepeatable | REPEATABLE READ | none | none | yes |
| nonrepeatable | SERIALIZABLE | none | none | yes |
| phantom | READ UNCOMMITTED | ANOMALY | ANOMALY | yes |
| phantom | READ COMMITTED | ANOMALY | ANOMALY | yes |
| phantom | REPEATABLE READ | write-only | write-only | yes |
| phantom | SERIALIZABLE | none | none | yes |
