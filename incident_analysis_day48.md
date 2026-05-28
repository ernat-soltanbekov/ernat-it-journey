# Incident Analysis — Week 10 Day 6

## Scenario

Critical financial platform migrated to:

```text
multi-region active-active architecture
```

Regions:

```text
Region A
Region B
Region C
```

Each region:
- accepted writes
- served users independently
- used local PostgreSQL cluster
- replicated asynchronously across regions

After major inter-region packet loss:
- balances diverged
- duplicate transactions appeared
- negative balances emerged
- reconciliation became impossible
- retries amplified inconsistency
- replay storms overloaded infrastructure

Infrastructure remained:
- operational
- green on dashboards
- healthy at node level

Business correctness collapsed.

---

# Root Cause

The platform violated distributed coordination assumptions.

Team attempted to combine:
- active-active writes
- asynchronous replication
- last-write-wins conflict resolution
- automatic failover

for:
- strongly consistent financial workloads

This architecture allowed:
- split brain
- divergent histories
- conflicting writes
- causal ordering loss

The system preserved:
- availability

by sacrificing:
- consistency

during network partition.

---

# CAP Theorem In Production

CAP theorem becomes relevant during:
- network partition

System must choose:

```text
Consistency
OR
Availability
```

under:
- partition conditions

The platform chose:
- availability

Regions continued accepting writes independently.

Result:
- business truth diverged

Infrastructure stayed operational while data correctness collapsed.

---

# Split Brain

Split brain occurs when:
- multiple regions believe their state is authoritative simultaneously

Each region:
- accepts writes
- processes payments
- mutates balances
- emits events independently

This creates:
- conflicting histories
- irreversible side effects
- duplicate financial operations

Split brain is catastrophic because:
- both sides may perform valid-looking but mutually incompatible actions

---

# Why Active-Active Is Dangerous

Active-active architecture works safely only when:
- conflicts are mergeable
- ordering is unimportant
- operations are commutative

Financial systems violate these assumptions.

Financial operations require:
- deterministic ordering
- monotonic balance history
- causality preservation
- strict invariants

Example:

```text
Withdraw $100
Close account
```

Reordering operations creates invalid state.

---

# Asynchronous Replication

Asynchronous replication introduces:
- replication lag

Writes acknowledged locally before remote regions confirm replication.

During partition:
- each region continues diverging independently

When connectivity restored:
- conflicting WAL histories collide

This creates:
- replay storms
- conflict amplification
- reconciliation overload

---

# Last-Write-Wins (LWW)

LWW resolves conflicts using:
- timestamps

This is dangerous because:
- clocks are unreliable
- causality is ignored
- ordering becomes nondeterministic

Clock drift may reorder events incorrectly.

LWW optimizes:
- convergence

not:
- correctness

For finance this is unacceptable.

---

# Clock Drift And Logical Time

Physical clocks cannot guarantee distributed ordering.

Problems:
- NTP drift
- asymmetric latency
- packet reordering
- network jitter

Distributed systems therefore use:
- logical clocks

---

# Lamport Clocks

Lamport clocks preserve:
- happened-before relationships partially

Purpose:
- establish logical ordering without synchronized clocks

---

# Vector Clocks

Vector clocks preserve:
- causality relationships more accurately

But:
- complexity grows rapidly at scale

Large systems often avoid generalized conflict resolution entirely.

Instead:
- authority centralized through leaders and quorum.

---

# Quorum

Quorum ensures:
- majority agreement

Example:

```text
3 nodes
quorum = 2
```

Two independent leaders cannot both achieve majority simultaneously.

Quorum prevents:
- split brain
- conflicting leaders
- concurrent authority

Without quorum:
- consistency impossible

---

# Leader Election

Distributed systems require:
- single authoritative writer

Protocols:
- Raft
- Paxos

Purpose:
- coordinated leader election
- replicated state agreement

---

# Stale Leaders

Network partitions may isolate leader.

Old leader may continue believing:
- lease still valid

This creates:
- stale leader problem

---

# Fencing Tokens

Fencing tokens prevent stale leaders from mutating state.

Every leadership epoch receives:
- monotonically increasing token

Storage rejects writes from:
- outdated leaders

Purpose:
- prevent stale authority corruption

---

# Automatic Failover Dangers

Automatic failover under unstable networks becomes:
- failure amplification engine

Transient packet loss may falsely trigger:
- leader elections
- replay storms
- lease invalidation
- replication cascades

Repeated failovers amplify:
- coordination instability

before infrastructure fully fails.

---

# Retry Amplification

Retries amplify:
- duplicate writes
- replay windows
- ordering uncertainty
- causal ambiguity

Retries increase:
- inconsistency surface area

not just:
- traffic volume

---

# Replay Storms

After recovery:
- all regions replay accumulated WAL logs simultaneously

This creates:
- massive write amplification
- queue saturation
- duplicate processing
- reconciliation overload

Recovery traffic often exceeds:
- original production traffic

This is:
- recovery amplification

---

# Exactly-Once Illusion

Exactly-once delivery is generally impossible across distributed boundaries.

Networks may:
- duplicate
- reorder
- replay
- partially fail

Practical systems target:

```text
exactly-once effects
```

through:
- idempotency
- deduplication
- transactional coordination

---

# Idempotency

Every financial operation requires:
- unique idempotency key

Consumers must:
- detect duplicates
- suppress replayed operations

Idempotency requires:
- durable deduplication storage
- transactional validation
- deterministic side effects

---

# Transactional Outbox Pattern

Database write and event publication must be atomic.

Solution:
- transaction writes business row
- transaction writes outbox event

Separate relay publishes:
- durable ordered events

Purpose:
- eliminate dual-write inconsistency

---

# Saga Pattern

Distributed transactions cannot truly rollback.

Sagas provide:
- forward recovery

Failures handled through:
- compensating actions

Example:
- refund transaction
instead of:
- erasing payment

---

# Why Reconciliation Became Impossible

Financial operations are:
- non-commutative

Meaning:

```text
A then B ≠ B then A
```

Once ordering and causality lost:
- deterministic merge impossible

Some business histories cannot be reconstructed safely.

---

# Healthy Infrastructure / Corrupted Business State

Infrastructure health means:
- processes alive
- packets flowing
- nodes operational

Business correctness requires:
- preserved coordination assumptions

Distributed systems may remain:
- operationally healthy

while becoming:
- logically corrupted

This is one of the hardest distributed systems failure modes.

---

# Investigation Process

## Replication Lag Analysis

Measure:
- WAL replication delay
- replication backlog growth
- region divergence timing

---

## Conflict Analysis

Identify:
- conflicting writes
- duplicated transactions
- overwritten histories

---

## Replay Analysis

Trace:
- replayed WAL sequences
- repeated event processing
- duplicate Kafka consumption

---

## Partition Timeline Reconstruction

Correlate:
- packet loss
- region isolation
- failover timing
- leader elections
- retry storms

---

## Duplicate Detection

Search:
- repeated idempotency keys
- duplicate payment IDs
- replayed event IDs

---

# Production Mitigation Plan

# Short-Term Stabilization

## Enter Read-Only Mode

Freeze writes globally.

Purpose:
- stop divergence growth

---

## Disable Automatic Failover

Prevent:
- additional leader instability

---

## Pause Replay And Reconciliation Workers

Purpose:
- stop recovery amplification

---

## Manual Conflict Resolution

Use:
- audit logs
- outbox records
- immutable event history

instead of:
- timestamps

---

# Long-Term Architecture

## Avoid Active-Active For Financial Balances

Prefer:
- single-writer authority
- home-region ownership
- strongly consistent coordination

---

## Strong Consistency

Use:
- quorum-based writes
- synchronous replication
- consensus systems

Examples:
- Spanner
- CockroachDB
- Raft-based systems

Tradeoff:
- higher write latency
- lower inconsistency risk

---

# Causal Consistency

Preserve:
- operation ordering
- happened-before relationships

Critical for:
- financial correctness

---

# Deterministic Conflict Resolution

Never rely solely on:
- timestamps

Use:
- business semantics
- version vectors
- monotonic sequencing

---

# Fencing Tokens

Protect storage from:
- stale leaders

Critical for:
- failover safety

---

# Duplicate Suppression

All side effects require:
- durable idempotency validation

Purpose:
- prevent replay corruption

---

# Key Learning

Distributed systems usually fail not because:
- machines stop working

but because:
- coordination assumptions stop being true

Healthy infrastructure does not guarantee:
- correct business state
