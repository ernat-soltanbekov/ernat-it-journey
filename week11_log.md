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

Studied consistency failures in event-driven architectures.

Key topics:
- Dual Write Problem
- At-most-once vs at-least-once delivery
- Idempotent consumer design
- Transactional Outbox Pattern
- Change Data Capture (CDC)
- Debezium architecture
- Event consistency guarantees
- Reconciliation processes
- Financial transaction safety

Completed incident analysis and mitigation planning for distributed order and payment processing systems.
