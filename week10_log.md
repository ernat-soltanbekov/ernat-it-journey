## 2026-05-23
- Studied Redis cache architecture and cache-aside pattern
- Learned stale reads and eventual consistency behavior
- Understood inconsistency windows and async invalidation risks
- Studied race conditions and distributed ordering failures
- Learned cache stampede and dogpile effect mechanics
- Compared cache-aside, write-through and write-behind strategies
- Analyzed read-after-write consistency and cache versioning
## 2026-05-24
- Studied PostgreSQL MVCC and transactional concurrency
- Learned row-level locking and lock queue amplification
- Understood deadlocks and transaction coordination collapse
- Studied isolation levels and consistency tradeoffs
- Learned connection pool exhaustion mechanics
- Analyzed hot row contention and optimistic locking
- Studied retry amplification at database layer
## 2026-05-25
- Studied Kafka architecture and distributed event streams
- Learned partitions, offsets and consumer group coordination
- Understood consumer lag and rebalance storm mechanics
- Studied delivery semantics and exactly-once limitations
- Learned idempotent consumer design and replay safety
- Analyzed hot partitions and backpressure amplification
- Studied retry storms and DLQ isolation patterns
## 2026-05-26
- Studied Kubernetes control plane architecture
- Learned API server and etcd coordination mechanics
- Understood reconciliation loops and watch storms
- Studied informer caches and controller amplification
- Learned etcd fsync latency and Raft coordination risks
- Analyzed service mesh control plane amplification
- Studied admission webhooks and CRD scalability risks
- Learned control plane backpressure and cluster instability patterns
## 2026-05-27
- Studied Linux TCP connection lifecycle and kernel networking limits
- Learned SYN backlog and accept queue behavior
- Studied conntrack table exhaustion and NAT amplification
- Learned TIME_WAIT mechanics and ephemeral port exhaustion
- Understood retry amplification at kernel networking layer
- Studied head-of-line blocking and TCP retransmissions
- Learned Kubernetes networking overhead and connection churn problems
- Studied production mitigation strategies for large-scale TCP overload
