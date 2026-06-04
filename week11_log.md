## 2026-05-30
- Studied connection pool saturation and PgBouncer bottlenecks
- Learned transaction pooling and connection lifecycle management
- Analyzed N+1 query amplification effects
- Studied head-of-line blocking and tail latency amplification
- Learned backpressure propagation across distributed systems
- Investigated database performance beyond CPU utilization metrics
## 2026-05-31
- Studied Kubernetes rolling update mechanics
- Learned maxUnavailable and maxSurge behavior
- Investigated scheduling failures and Pending Pods
- Studied resource requests versus limits
- Learned resource fragmentation and node capacity constraints
- Analyzed Cluster Autoscaler limitations
- Studied storage topology and volume affinity conflicts
- Learned capacity planning for node failures and deployments
## 2026-06-01
- Studied Istio certificate rotation failures
- Learned mTLS architecture and workload identity concepts
- Analyzed Envoy sidecars and SDS secret distribution
- Investigated trust bundle propagation and stale proxy states
- Learned production troubleshooting of Service Mesh outages
- Studied certificate expiration monitoring and safe CA rotation strategies
### Day 53 - Dual Write Problem and Transactional Outbox
- Dual Write Problem
- At-most-once vs at-least-once delivery
- Idempotent consumer design
- Transactional Outbox Pattern
- Change Data Capture (CDC)
- Debezium architecture
- Event consistency guarantees
- Reconciliation processes
- Financial transaction safety
### Day 54 - Kubernetes Memory Pressure and Pod Evictions
- Resource requests and limits
- Allocatable vs actual resource consumption
- Memory overcommit and node overpacking
- Kubelet Eviction Manager
- OOMKilled vs Evicted
- Kubernetes QoS classes
- MemoryPressure conditions
- Capacity planning
- Vertical Pod Autoscaler (VPA)
- Goldilocks recommendations
### Day 55: Investigated PostgreSQL replication lag, recovery conflicts, WAL replay delays, and read-after-write consistency strategies.
